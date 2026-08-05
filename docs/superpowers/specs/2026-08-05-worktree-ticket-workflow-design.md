# Worktree-basierter Ticket-Workflow mit herdr

**Datum:** 2026-08-05
**Status:** Entwurf abgenommen, Umsetzung offen

## Zweck

Ein Ticket soll mit einem Kommando zu einem arbeitsfähigen, isolierten Arbeitsplatz
werden: eigener Git-Worktree, eigener Docker-Stack, eigene Ports, eigener Claude —
und mehrere davon gleichzeitig, sichtbar als Spaces in der herdr-Sidebar.

Zwei Abläufe darauf: **Bugfix** (reproduzieren → fixen → Ticket → Draft-MR) und
**Feature** (planen → Freigabe → TDD → Review → Draft-MR).

## Ausgangslage

Die Arbeit findet auf zwei Rechnern statt (privat, Arbeit). Das Arbeitsprojekt ist
von hier nicht erreichbar; alles muss über die Dotfiles wandern und
projekt-agnostisch sein. Branch-Konventionen, MR-Tooling und der Atlassian-MCP
liegen auf dem Arbeitsrechner vor.

### Was herdr 0.8.0 mitbringt

- `herdr worktree create --branch <name> --base <ref>` legt Worktree **und**
  Sidebar-Workspace an (Ablage konfigurierbar über `[worktrees] directory`).
- Agent-Lifecycle als erstklassiges Konzept: `idle` / `working` / `blocked` /
  `done` / `unknown` pro Pane, benannte Agents, `agent prompt --wait`,
  `agent wait --until blocked`, `agent read`.
- Vollständig skriptbare Socket-API mit JSON-Antworten
  (`workspace | tab | pane | agent | worktree | notification`).
- Persistente Sessions (`--session <name>`, `--remote <ssh-target>`).
- Mitgeliefertes Agent-Skill über `herdr --skill`.

### Was herdr nicht mitbringt

- **Keine Post-Create-Hooks.** `worktree create` erzeugt Worktree und Workspace,
  nichts weiter — kein `docker compose up`, kein `npm ci`, kein `.env`.
- Kein Wissen über Tickets, Branch-Konventionen oder Merge Requests.
- **Keine Port-Isolation.** Diese Lücke hat auch Superset nicht geschlossen.

### Verhältnis zu Superset

Superset löst den Bootstrap-Teil bereits nativ: `.superset/config.json` mit
`setup` / `teardown` / `run` / `cwd`, ausgeführt beim Anlegen und Löschen eines
Workspace, plus `.superset/config.local.json` (gitignored) für persönliche
Ergänzungen. herdr gewinnt hier trotzdem, weil es ein tastaturgesteuerter
Terminal-Multiplexer mit Agent-Lifecycle in der Sidebar ist — genau die
gewünschte Arbeitsweise.

**Konsequenz für den Entwurf:** Die Projekt-Konfiguration benutzt bewusst
Supersets Schlüssel `setup`, `teardown` und `cwd` wörtlich. Ein Wechsel zurück
kostet dann ein Kopieren der Datei, keine Neuarbeit.

## Architektur

Fünf Teile, jeder mit einer Aufgabe. Die Trennlinie ist bewusst gezogen:
**fragile Infrastruktur-Arbeit einmal fest verdrahtet im Skript, Ablauf-Logik
dort, wo sie flexibel sein muss (Skills).**

### 1. `wt` — das Bootstrap-Kommando

Ort: `dotfiles/.local/bin/wt` (zsh; `~/.local/bin` liegt im PATH).

Weiß nichts über Tickets, Git-Flow oder Jira. Gibt JSON aus und setzt Exit-Codes,
ist also von Mensch und Agent gleichermaßen bedienbar.

| Kommando | Wirkung |
|---|---|
| `wt new <slug> [--base <ref>]` | Basis-Branch aktualisieren, Worktree + Workspace anlegen, Ports zuweisen, Setup ausführen, Tabs und Dienste aufbauen. JSON: Pfad, Branch, Ports, Workspace-/Tab-/Pane-IDs, Agent-Pane. |
| `wt ls` | Alle Worktrees mit Branch, Ports, Stack-Status |
| `wt up <slug>` / `wt down <slug>` | Dienste starten / stoppen |
| `wt rm <slug> [--force]` | Teardown, Worktree entfernen, Workspace schließen |
| `wt prune` | Worktrees, deren Branch in die Basis gemerged ist, nach Bestätigung abräumen |
| `wt ports <slug>` | Zugewiesene Ports und URLs |
| `wt doctor` | Repo untersuchen, Konfigurations-Gerüst erzeugen, Compose-Version prüfen |

### 2. Projekt-Konfiguration

Ort: `~/.config/wt/<repo-name>.json`, in den Dotfiles unter `dotfiles/.config/wt/`.
Bewusst **außerhalb** des Repos, damit im Firmen-Repo keine Fremddateien liegen.
`wt` findet sie über den Repo-Namen des aktuellen Verzeichnisses; mehrere Projekte
parallel brauchen kein Umschalten.

```json
{
  "repo": "~/work/projekt",
  "base": "develop",
  "branch_pattern": "{type}/{ticket}-{slug}",
  "cwd": null,

  "setup":    ["cp $WT_MAIN/.env .env", "npm ci", "docker compose up -d"],
  "teardown": ["docker compose down -v"],

  "tabs": [
    { "name": "claude", "agent": "claude" },
    { "name": "edit",   "command": "nvim" },
    { "name": "stack",  "panes": [
        { "name": "server", "command": "npm run dev" },
        { "name": "client", "command": "npm start", "direction": "right" }
    ]}
  ],

  "ports": { "mode": "env", "vars": { "APP_PORT": 8080, "VITE_PORT": 5173, "DB_PORT": 5432 } }
}
```

Entscheidungen dazu:

- **`docker compose up -d` gehört ins Setup, nicht in ein Pane** — es ist detached,
  es gibt kein Log zum Zusehen. In den Panes stehen nur Prozesse, die im
  Vordergrund laufen.
- **`setup`, `teardown` und `cwd` bleiben Superset-kompatibel**; `tabs` ist die
  Erweiterung für herdr-Layout. `cwd` ist optional (Monorepo-Unterverzeichnis)
  und gilt für Setup-, Teardown- und Pane-Kommandos.
- **`branch_pattern`** kennt drei Platzhalter: `{type}` (`bugfix` oder `feature`),
  `{ticket}` (Jira-ID, leer wenn keine vorliegt) und `{slug}` (Kurzform des
  Titels). Fehlt die Ticket-ID, entfällt das Segment ohne doppelten Trenner.
- **`--base`** überschreibt `base` nur für einen einzelnen Aufruf.
- **Layout ist Konfiguration**, weil es pro Projekt leicht abweicht. Basis:
  Tab 1 Claude, Tab 2 Neovim, Tab 3 Stack (Server links, Client rechts).
- Ein Pane mit laufendem nvim gilt für herdr als belegt — dort kann kein Agent
  gestartet werden, was hier korrekt ist.

### 3. `/wt-setup` — die Konfiguration wird generiert, nicht getippt

Eine Konfiguration pro Projekt ist unvermeidbar; kein Werkzeug kann erraten, wie
ein Projekt startet. Das Problem ist nur, sie schreiben zu müssen. Also:

Einmal pro Projekt im Repo aufrufen. Der Skill liest `package.json`-Scripts,
Compose-Datei, `Makefile`, `README` und `.env.example`, schlägt die Konfiguration
vor, nimmt Korrekturen auf und **verifiziert sie, indem ein Wegwerf-Worktree damit
hochgefahren wird**. Erst wenn Stack und Dev-Server sauber starten, gilt sie als
fertig.

Entlastungen:

- Hat das Projekt ein eigenes Startskript, wird dorthin delegiert
  (`"setup": ["make bootstrap"]`) statt es nachzubauen.
- **Ohne Konfiguration kein Blocker:** `wt new` legt dann nur Worktree und leere
  Tabs an — also mindestens das, was herdr allein kann, nie schlechter.
- Nachschärfen ist normal: fehlt beim dritten Ticket eine Migration im Setup,
  kommt eine Zeile dazu und alle künftigen Worktrees haben sie.

**Bekannte Schwäche:** Weil die Datei außerhalb des Repos liegt, bekommt sie
Änderungen im Projekt (neues Script, geänderter Port) nicht mitgeteilt und kann
veralten. Symptom ist ein fehlschlagendes Setup mit klarer Fehlermeldung, kein
stiller Defekt.

### 4. Hub-Skills

- **`/ticket <ID | Freitext | beides>`** — legt an, briefet, startet den Worker,
  **behält deinen Fokus**, meldet eine Zeile zurück. Direkt danach kann das
  nächste Ticket raus.
- **`/tickets`** — Statusübersicht über alle Spaces aus `herdr agent list` und
  `wt ls`: wer arbeitet, wer ist `blocked`, wer ist `done`.

### 5. Worker-Playbooks

Eigene Skills (`bugfix-workflow`, `feature-workflow`), nicht ein langer Prompt —
so sind sie änderbar, ohne den Hub anzufassen, und auch manuell aufrufbar, wenn
man schon im Worktree sitzt.

## Ablauf: Hub

1. Eingabe deuten. Jira-ID vorhanden → Ticket über den Atlassian-MCP holen; nur
   Freitext → damit arbeiten und das Ticket am Ende aus dem tatsächlichen Befund
   anlegen. Typ (Bug/Feature) wird erkannt, bei Zweifel wird gefragt.
2. Branch-Namen nach `branch_pattern` aus der Konfiguration bilden.
3. `wt new` aufrufen.
4. Briefing in den Worktree schreiben (siehe *Gedächtnis auf der Platte*).
5. `herdr agent start <name> --kind claude --pane <agent-pane> --no-focus`, dann
   `herdr agent prompt <name> "Lies .wt/BRIEFING.md und folge dem
   <playbook>-Skill."`
6. Eine Zeile an den Benutzer: Space, Ports, Agent-Name.

## Ablauf: Bugfix

1. **Reproduzieren im Browser.** Stack läuft, der Worker öffnet über die
   Chrome-Automatisierung *seinen* Port, loggt sich ein und spielt die
   Ticket-Schritte nach. Ergebnis ist eine von drei Feststellungen: Fehler tritt
   auf / tritt nicht auf (evtl. bereits behoben) / Schritte nicht durchführbar.
   Belege: Screenshot, `read_console_messages`, `read_network_requests`. Nur bei
   Tickets ohne Oberflächenbezug (API, Job, CLI) Rückfall auf einen
   fehlschlagenden Test.
2. **Nicht reproduzierbar → kurze Meldung, Schluss.** „Nicht reproduzierbar, das
   habe ich versucht, ich brauche mehr Infos." Kein Verhör, kein Patchen auf
   Verdacht. `blocked` plus `herdr notification show`.
3. **Fix per TDD** — Test rot, Fix, Test grün; der Test bleibt als
   Regressionsschutz.
4. **Verifizieren** über `verification-before-completion`: Suite grün *und* die
   ursprüngliche Abfolge im Browser erneut durchgespielt.
5. **Commit + Push** nach den Konventionen des Projekts.
6. **Ticket** — vorhanden: Jira-Kommentar mit Ursache, Fix, Testnachweis. Nicht
   vorhanden: jetzt anlegen, mit dem gefundenen Befund.
7. **Merge Request als Draft** aus Ursache, Fix, Testnachweis,
   Reproduktionsschritten. Draft ist Standard: Umstellen auf „fertig" ist ein
   Klick, ein versehentlich ausgelöstes Review kostet Kollegen Zeit.

**Harte Haltepunkte:** nicht reproduzierbar (Schritt 2); und wenn der Fix
deutlich größer ausfällt als das Ticket hergibt (etwa Umbau in gemeinsam
genutztem Code) — dann **erst einen Plan vorlegen** (Ursache, geplante Änderung,
betroffene Bereiche, Risiko) und Freigabe abwarten, nie im Alleingang.

## Ablauf: Feature

1. **Kontext lesen** — Ticket, betroffener Code, bestehende Muster. Neues soll
   aussehen wie der Code drumherum.
2. **Recherche, wenn es etwas zu recherchieren gibt** — fremde Library, unklares
   API-Verhalten, Best Practice: Web-Suche und Doku, mit Quellenlinks im Plan.
   Kein Pflichtritual.
3. **Plan vorlegen — harter Haltepunkt.** Umsetzungsschritte, betroffene Dateien,
   geplante Tests, offene Fragen, Recherche-Belege. `blocked` plus
   Benachrichtigung, dann warten. Hier liegt der eigentliche Wert: Richtung
   korrigieren, bevor Code entsteht.
4. **Umsetzung per TDD**, in Schritten mit grünen Tests nach jedem Schritt.
5. **Browser-Verifikation** bei betroffener Oberfläche, inklusive Screenshots.
6. **`/code-review`** auf den eigenen Stand. Befunde werden über
   `receiving-code-review` *bewertet*, nicht blind abgearbeitet — technisch
   falsche Punkte werden begründet abgelehnt.
7. **Commit, Push, Draft-MR** mit Plan-Zusammenfassung, Testnachweis und
   Screenshots; Ticket in Jira aktualisieren oder anlegen.

**Schaltbare Pflichtschritte:** `tests`, `review` und `research` stehen als
Vorgaben im Briefing. Standard: Tests und Review an, Recherche nach Bedarf.
Abweichen beim Auslösen (`/ticket … ohne Review, ist ein Spike`).

## Gedächtnis auf der Platte

Features dauern länger als eine Sitzung. Jeder Worktree führt daher mit:

- `.wt/BRIEFING.md` — Auftrag und Vorgaben
- `.wt/PLAN.md` — der freigegebene Plan, mit abgehakten Schritten
- `.wt/JOURNAL.md` — Entscheidungen und Erkenntnisse unterwegs
- `.wt/TICKET.md` — nur wenn Jira nicht erreichbar war: Ticket-Text zum Nachtragen

`wt up <slug>`, frischer Claude im Space, diese Dateien lesen — und er ist wieder
im Bild, ohne dass Kontext erzählt werden muss.

Ausgeschlossen über `.git/info/exclude`, **nicht** über die `.gitignore` des
Projekts, damit im Firmen-Repo nichts verändert wird.

## Isolation

**Ports.** Jeder Worktree bekommt einen kleinen ganzzahligen Versatz,
deterministisch aus dem Slug abgeleitet — `PROJ-1234` ergibt z. B. Versatz 3, also
`VITE_PORT=5176`, `APP_PORT=8083`, `DB_PORT=5435`. Lesbar, und beim zweiten Öffnen
dieselben Werte. Beim Anlegen werden alle Werte auf Belegung geprüft; ist einer
besetzt, rückt der Versatz weiter. Die gewählte Zahl wird in
`~/.local/state/wt/<repo>/<slug>.json` festgehalten und ist ab dann fix.

Die Werte gehen zwei Wege gleichzeitig:

- als markierter, idempotenter Block in die `.env` des Worktrees
  (`# >>> wt` … `# <<< wt`), damit Compose sie sieht;
- als Umgebungsvariablen in die Panes, damit Server und Vite sie sehen.

**Container.** `COMPOSE_PROJECT_NAME=<repo>-<slug>` — eigene Container, eigene
Netzwerke, **eigene Volumes**, also ein eigener Migrationsstand pro Ticket. Das
ist der wichtigere Teil der Isolation: neue Dependencies und Migrations in einem
Ticket dürfen ein anderes nicht anfassen.

**Feste Ports in der Compose-Datei.** Dann erzeugt `wt` eine
`docker-compose.override.yml` mit `ports: !override [...]`. Wichtig: Compose
*hängt* `ports`-Listen normalerweise an statt sie zu ersetzen — ohne `!override`
bliebe das alte Binding bestehen und die Kollision genau erhalten. `!override`
wirkt erst ab Compose 2.24, deshalb prüft `wt doctor` die Version und warnt.

**Ein Chrome für alle Worker.**

- Sitzungen kollidieren nicht: eigener Port je Worktree, Cookies sind
  portspezifisch, jeder Worker hat seinen eigenen Login.
- Aber Klick- und Screenshot-Steuerung braucht den sichtbaren Tab. Deshalb
  Vorrang für die tab-gezielten Werkzeuge (`navigate`, `find`, `form_input`,
  `read_page`, Konsole, Netzwerk), die im Hintergrund arbeiten; pixelbasierte
  Steuerung nur wenn nötig und dann über eine Sperrdatei
  (`~/.local/state/wt/browser.lock`) serialisiert — wer sie nicht bekommt, wartet.
- Einmalig nötig: `localhost` in der Chrome-Erweiterung freigeben.

## Fehlerfälle

| Fall | Verhalten |
|---|---|
| Basis-Branch lässt sich nicht aktualisieren | Abbruch **vor** dem Anlegen — kein halbfertiger Worktree |
| Branch existiert schon | Kein Fehler: bestehender Worktree wird geöffnet, Arbeit fortgesetzt |
| Setup schlägt fehl | Worktree bleibt stehen, fehlgeschlagenes Kommando und Pane werden benannt, **kein Worker wird gestartet** |
| Alle Ports belegt | Abbruch mit Klartext |
| herdr-Server läuft nicht | `wt` legt nur den Worktree an und nennt den Pfad — schlechter als mit herdr, aber nie kaputt |
| Worker-Agent startet nicht in 30 s | Space bleibt, Meldung an den Benutzer, manuelle Übernahme |
| Jira/MCP nicht erreichbar | Ticket-Text nach `.wt/TICKET.md`; die Arbeit läuft weiter |

**Sicherheitsnetz:** Das Playbook prüft vor jedem Commit, dass der aktuelle Branch
nicht der Basis-Branch ist. Ein Worker, der versehentlich auf `develop` committet
oder pusht, ist der einzige Fehler in diesem Entwurf, der wirklich weh täte.

**Aufräumen ist Pflicht, nicht Kosmetik:** Jeder Worktree hat eigene
`node_modules` und eigene DB-Volumes. Parallele Isolation kostet Plattenplatz;
ohne `wt rm` und `wt prune` sammelt sich das an.

## Voraussetzungen auf dem Zielrechner

Geprüft auf dem Privatrechner (2026-08-05):

- herdr 0.8.0 via Homebrew, Server läuft, `HERDR_ENV=1` in den Panes.
- `herdr integration status` → `claude: current (v7)`
  (`~/.claude/hooks/herdr-agent-state.sh`). Das ist der Teil, der den
  Agent-Zustand an die Sidebar meldet — Voraussetzung dafür, dass `blocked`
  überhaupt sichtbar wird.
- `settings.json` erlaubt `Bash(*)`, die herdr-CLI ist also ohne Rückfrage
  aufrufbar.
- **Fehlt noch:** das herdr-Agent-Skill unter `~/.claude/skills/herdr/SKILL.md`
  (`herdr --skill` schreibt es). Es enthält die Regeln, ohne die die CLI
  ungeschickt bedient wird — IDs aus JSON lesen statt raten, `--no-focus` für
  Hintergrundarbeit, `--current` statt auf fremden Fokus zu vertrauen, Bedeutung
  von `idle` gegenüber `done` und `unknown`. **Erster Umsetzungsschritt.**

Auf dem Arbeitsrechner zusätzlich zu prüfen: Atlassian-MCP, MR-Tooling
(`glab`/`gh`), Compose-Version, Branch-Konventionen.

## Umsetzungsreihenfolge

Der Entwurf ist größer als ein Umsetzungsschritt. Sinnvolle Staffelung, jede Stufe
für sich benutzbar:

1. **herdr-Skill installieren** (`herdr --skill` → `~/.claude/skills/herdr/SKILL.md`).
   Danach ist die CLI sauber steuerbar.
2. **`wt` Kern** — `new`, `ls`, `rm` mit Worktree, Workspace, Tabs, Setup,
   Port-Zuteilung, Teardown. Ab hier ist manuelles Arbeiten in isolierten
   Worktrees möglich, ohne jeden Skill.
3. **`/wt-setup`** — Konfiguration generieren und gegen einen Wegwerf-Worktree
   verifizieren. Ab hier ist ein echtes Projekt angebunden.
4. **`bugfix-workflow`** — der Ablauf, der den größeren Alltagsanteil hat.
5. **`/ticket` und `/tickets`** — das Hub-Modell obendrauf.
6. **`feature-workflow`**, dann `wt up` / `down` / `prune` / `ports` / `doctor` als
   Abrundung.

## Nicht Teil dieses Entwurfs

- Aufräumen der acht Superset-Notify-Hooks in `settings.json`. Sie sind über
  `[ -n "$SUPERSET_HOME_DIR" ]` abgesichert und tun ohne Superset nichts, sind
  aber toter Ballast. Eigene, kleine Sache.
- Entscheidung, ob Superset parallel weiterläuft. Ändert am Entwurf nichts.
- Automatisches Erkennen veralteter Projekt-Konfigurationen.

# `wt` Bootstrap-Kommando — Umsetzungsplan (Plan A)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein Kommando `wt`, das aus einem Slug einen arbeitsfähigen, isolierten Git-Worktree macht — eigene Ports, eigener Docker-Stack, herdr-Workspace mit dem konfigurierten Tab-Layout — und ihn wieder abräumt.

**Architecture:** Ein zsh-Executable `bin/wt` als Argument-Parser und Dispatcher (installiert als Symlink `~/.local/bin/wt`), dahinter sechs Bibliotheksdateien mit je einer Zuständigkeit (Konfiguration, Ports, Umgebungsdateien, Git, herdr, Zustand). Alle Seiteneffekte sitzen hinter Umgebungsvariablen-Nahtstellen, damit die Tests hermetisch laufen: `WT_CONFIG_DIR`, `WT_STATE_DIR`, `WT_WORKTREE_DIR`, `WT_HERDR_BIN`, `WT_LIB`. `wt new --dry-run` gibt den vollständigen Ausführungsplan als JSON aus, ohne etwas anzufassen — das ist gleichzeitig die Testschnittstelle für die Orchestrierung und die Vertrauensschnittstelle für den Benutzer.

**Tech Stack:** zsh 5.9 (macOS-eigen, keine Zusatzabhängigkeit), `jq` 1.8.2 für JSON, `git worktree`, `nc` für Port-Prüfung, `herdr` 0.8.0 CLI, `bats-core` für Tests.

**Spec:** `docs/superpowers/specs/2026-08-05-worktree-ticket-workflow-design.md`

## Global Constraints

- **Ort: eigenes Repo unter `~/development/wt`.** `wt` ist ein Programm, keine Konfiguration, und gehört deshalb nicht in die Dotfiles. Dort bleibt nur, was Konfiguration ist: die Projekt-Dateien unter `.config/wt/` und der `bats-core`-Eintrag im Brewfile. Alle Pfadangaben in diesem Plan sind relativ zur Wurzel des `wt`-Repos, außer sie nennen `~/dotfiles` ausdrücklich.
- **Sprache: zsh, nicht bash.** macOS liefert bash 3.2 (keine assoziativen Arrays); zsh 5.9 ist vorhanden und ist die Shell des Benutzers.
- **Kein `shellcheck`.** Es unterstützt zsh nicht. Lint-Schritt ist `zsh -n <datei>` für jede Datei.
- **Port-Prüfung: `nc -z 127.0.0.1 <port>`, Exit 0 = belegt.** Verifiziert am 2026-08-05. **Nicht** `-G 1` ergänzen — damit liefert `nc` auch bei belegtem Port Exit 1 und die Prüfung wird wertlos.
- **Niemals `local path` in zsh.** `path` ist an `PATH` gekoppelt (als Array); eine lokale Deklaration leert `PATH` im gesamten Funktionsrumpf, und jeder Aufruf eines externen Kommandos scheitert mit „command not found". Nachgewiesen am 2026-08-05: `zsh -c 'f() { local path; echo "[$PATH]" }; f'` gibt `[]` aus. Dieser Plan benutzt deshalb `wt_path`, `cfg_path` und `jq_path`. Dasselbe gilt für die weiteren gekoppelten Namen `cdpath`, `fpath`, `manpath`. **Die Abhilfe ist immer der andere Variablenname — nie ein Retten und Wiederherstellen von `PATH`.** In den bats-Tests (bash) ist `path` unproblematisch und bleibt.
- **Kein `setopt err_return`.** In zsh bricht damit auch ein `[[ bedingung ]] && aktion` mit falscher Bedingung die ganze Funktion ab, weil die Kette Exit 1 liefert. Fehlerbehandlung läuft ausschließlich explizit über `|| wt_die` bzw. `|| return 1`. Gesetzt werden nur `no_unset` und `pipe_fail`.
- **`herdr workspace close` nimmt die ID positional** (`herdr workspace close w9`), **nicht** als `--workspace`. Verifiziert am 2026-08-05. Gleiches gilt für `workspace focus`.
- **Ausgabe:** stdout gehört den Daten. Mit `--json` steht dort ausschließlich ein JSON-Objekt. **Fortschritts-, Hinweis- und Fehlermeldungen gehen immer nach stderr** — auch die Zeilen, die Setup- und Teardown-Schritte mitschreiben. Sonst zerbricht `wt new --json | jq` an der ersten Fortschrittszeile. Exit ≠ 0 bei Fehlern, Exit 2 nur für Aufrufsyntax-Fehler.
- **Nichts im Ziel-Repo verändern**, was eingecheckt ist. Erlaubt sind nur worktree-lokale Dateien (`.env`, `docker-compose.override.yml`, `.wt/`) und `.git/info/exclude`. Niemals die `.gitignore` des Projekts anfassen.
- **Compose `!override` wirkt erst ab Docker Compose 2.24.**
- **Konfiguration** liegt in `${WT_CONFIG_DIR:-$HOME/.config/wt}/<repo-name>.json`, **Zustand** in `${WT_STATE_DIR:-$HOME/.local/state/wt}/<repo-name>/<slug>.json`.
- **Port-Offset-Bereich: 1–40**, Startwert `cksum(slug) % 40 + 1`.
- **herdr-Aufrufe** immer über `${WT_HERDR_BIN:-herdr}` und immer mit `--no-focus`, wo das Flag existiert. IDs ausschließlich per `jq` aus der Antwort lesen, nie erraten.
- Alle Bibliotheksdateien sind Funktionssammlungen ohne Seiteneffekte beim Sourcen.

---

## File Structure

| Datei | Zuständigkeit |
|---|---|
| `bin/wt` | Argument-Parsing, Subkommando-Dispatch, Hilfe, Version. Keine Fachlogik. |
| `lib/util.zsh` | `wt_die`, `wt_warn`, `wt_json_get`, `wt_require_cmd` |
| `lib/config.zsh` | Repo-Wurzel und -Name ermitteln, Konfiguration finden, laden, mit Vorgabewerten mischen, validieren |
| `lib/ports.zsh` | Offset berechnen, Belegung prüfen, Ports zuteilen |
| `lib/state.zsh` | Zustandsdatei lesen, schreiben, löschen, auflisten |
| `lib/envfile.zsh` | `.env`-Block schreiben, `docker-compose.override.yml` erzeugen |
| `lib/git.zsh` | Basis-Branch aktualisieren, Worktree anlegen, entfernen, gemergte finden |
| `lib/herdr.zsh` | Workspace, Tabs, Panes nach Konfiguration aufbauen |
| `tests/helper.bash` | Testhilfen: Fixture-Repo, herdr-Attrappe, temporäre Verzeichnisse |
| `tests/*.bats` | Eine Datei pro Bibliothek |

`wt` findet seine Bibliothek über `WT_LIB="${WT_LIB:-${0:A:h:h}/lib}"`. `${0:A}` löst in zsh Symlinks auf: aufgerufen als `~/.local/bin/wt` (Symlink) landet der Ausdruck bei `~/development/wt/lib`, direkt im Repo aufgerufen ebenso. Dadurch braucht nur die eine Datei `bin/wt` einen Symlink, die Bibliothek keinen.

---

### Task 1: Test-Harness, Skelett, herdr-Skill

**Files:**
- Create: `bin/wt`
- Create: `lib/util.zsh`
- Create: `tests/helper.bash`
- Create: `tests/cli.bats`
- Create: `.gitignore`
- Modify (im Dotfiles-Repo): `Brewfile`
- Create (außerhalb des Repos): `~/.claude/skills/herdr/SKILL.md`

**Interfaces:**
- Consumes: nichts
- Produces: `wt_die <msg>` (schreibt nach stderr, Exit 1), `wt_warn <msg>`, `wt_require_cmd <name>`; Executable `bin/wt` mit `--version`, `help`, Dispatch-Tabelle

- [ ] **Step 1: bats-core installieren und in den Dotfiles festhalten**

`bats-core` ist eine Werkzeug-Abhängigkeit der Maschine, gehört also ins Brewfile der Dotfiles — nicht in dieses Repo. In `~/dotfiles/Brewfile` nach der Zeile `brew "jq"` einfügen:

```ruby
brew "bats-core"
```

Dann installieren:

```bash
brew install bats-core
bats --version
```

Expected: eine Version ≥ 1.11

Dieser eine Commit landet im Dotfiles-Repo, alle weiteren in `~/development/wt`.

- [ ] **Step 2: `.gitignore` anlegen**

`.gitignore`:

```
# Arbeitsverzeichnis der Subagent-Reviews
.superpowers/
```

- [ ] **Step 3: Test-Helfer schreiben**

`tests/helper.bash`:

```bash
# Gemeinsame Hilfen für alle wt-Tests.
WT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
WT_BIN="$WT_ROOT/bin/wt"
export WT_LIB="$WT_ROOT/lib"

# Ruft das Kommando unter Test auf. Nutzung: run wt config show
# $output enthält dabei stdout UND stderr, taugt also für Meldungsprüfungen.
wt() { "$WT_BIN" "$@"; }

# Nur stdout, ohne Fortschrittszeilen. Für Tests, die JSON auswerten:
#   run wt_json new foo --json
# Ohne das würde jq an der ersten "wt: Setup: …"-Zeile scheitern.
wt_json() { "$WT_BIN" "$@" 2>/dev/null; }

# Frische, isolierte Verzeichnisse für Konfiguration, Zustand und Worktrees.
wt_tmpdirs() {
  WT_TMP="$(mktemp -d)"
  export WT_TMP
  export WT_CONFIG_DIR="$WT_TMP/config"
  export WT_STATE_DIR="$WT_TMP/state"
  export WT_WORKTREE_DIR="$WT_TMP/worktrees"
  mkdir -p "$WT_CONFIG_DIR" "$WT_STATE_DIR" "$WT_WORKTREE_DIR"
}

wt_cleanup() {
  [ -n "${WT_TMP:-}" ] && rm -rf "$WT_TMP"
}

# Fixture-Repo mit main + develop und einem Commit. Kein Remote.
wt_fixture_repo() {
  export WT_REPO="$WT_TMP/projekt"
  mkdir -p "$WT_REPO"
  git -C "$WT_REPO" init -q -b main
  git -C "$WT_REPO" config user.email t@example.com
  git -C "$WT_REPO" config user.name Test
  echo hallo > "$WT_REPO/README.md"
  git -C "$WT_REPO" add -A
  git -C "$WT_REPO" commit -qm init
  git -C "$WT_REPO" branch develop
}

# Attrappe für herdr: schreibt jeden Aufruf mit und liefert plausibles JSON.
wt_stub_herdr() {
  export WT_HERDR_BIN="$WT_TMP/herdr-stub"
  export WT_HERDR_LOG="$WT_TMP/herdr.log"
  : > "$WT_HERDR_LOG"
  cat > "$WT_HERDR_BIN" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$WT_HERDR_LOG"
case "$1 $2" in
  "worktree create"|"workspace create")
    echo '{"result":{"workspace":{"workspace_id":"w9"},"tab":{"tab_id":"w9:t1"},"root_pane":{"pane_id":"w9:p1"}}}' ;;
  "tab create")
    echo '{"result":{"tab":{"tab_id":"w9:t2"},"root_pane":{"pane_id":"w9:p2"}}}' ;;
  "pane split")
    echo '{"result":{"pane":{"pane_id":"w9:p3"}}}' ;;
  "workspace list")
    echo '{"result":{"workspaces":[{"workspace_id":"w9","label":"projekt"}]}}' ;;
  *)
    echo '{"result":{}}' ;;
esac
STUB
  chmod +x "$WT_HERDR_BIN"
}
```

- [ ] **Step 4: Den fehlschlagenden Test schreiben**

`tests/cli.bats`:

```bash
#!/usr/bin/env bats

load helper

setup()    { wt_tmpdirs; }
teardown() { wt_cleanup; }

@test "--version nennt Name und Version" {
  run wt --version
  [ "$status" -eq 0 ]
  [[ "$output" == wt\ 0.1.0* ]]
}

@test "help listet alle Subkommandos" {
  run wt help
  [ "$status" -eq 0 ]
  for sub in new ls up down rm prune ports config doctor; do
    [[ "$output" == *"$sub"* ]]
  done
}

@test "unbekanntes Subkommando endet mit Exit 2 und Meldung auf stderr" {
  run wt quatsch
  [ "$status" -eq 2 ]
  [[ "$output" == *"unbekanntes Subkommando: quatsch"* ]]
}

@test "ohne Argumente wird die Hilfe gezeigt, Exit 2" {
  run wt
  [ "$status" -eq 2 ]
  [[ "$output" == *"Aufruf:"* ]]
}
```

- [ ] **Step 5: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/cli.bats`
Expected: FAIL — `wt` existiert noch nicht (`command not found` bzw. Permission denied)

- [ ] **Step 6: `util.zsh` schreiben**

`lib/util.zsh`:

```zsh
# Ausgabe- und Prüfhilfen. Keine Seiteneffekte beim Sourcen.

wt_warn() {
  print -u2 -- "wt: $*"
}

wt_die() {
  print -u2 -- "wt: $*"
  exit 1
}

wt_usage_die() {
  print -u2 -- "wt: $*"
  exit 2
}

# Verlangt ein Kommando im PATH.
wt_require_cmd() {
  local cmd=$1
  whence -p "$cmd" >/dev/null || wt_die "benötigtes Kommando fehlt: $cmd"
}

# Liest einen Wert per jq-Pfad aus einem JSON-String. Leer, wenn nicht vorhanden.
wt_json_get() {
  local json=$1 jq_path=$2
  printf '%s' "$json" | jq -r "$jq_path // empty" 2>/dev/null
}
```

- [ ] **Step 7: `wt`-Skelett schreiben**

`bin/wt`:

```zsh
#!/usr/bin/env zsh
# wt — Worktree-Arbeitsplätze anlegen, betreiben und abräumen.
emulate -L zsh
# Kein err_return: es würde jedes "[[ bedingung ]] && aktion" mit falscher
# Bedingung zum Funktionsabbruch machen. Fehler werden explizit behandelt.
setopt no_unset pipe_fail

typeset -g WT_VERSION=0.1.0
typeset -g WT_LIB="${WT_LIB:-${0:A:h:h}/lib}"

source "$WT_LIB/util.zsh"

wt_help() {
  cat <<'EOF'
Aufruf: wt <subkommando> [optionen]

  new <slug> [--base <ref>] [--dry-run] [--json]  Worktree anlegen und einrichten
  ls [--json]                                     Worktrees mit Branch, Ports, Status
  up <slug>                                       Dienste starten
  down <slug>                                     Dienste stoppen
  rm <slug> [--force]                             Teardown, Worktree und Workspace entfernen
  prune                                           Gemergte Worktrees abräumen
  ports <slug> [--json]                           Zugeteilte Ports und URLs
  config show [--json]                            Aufgelöste Projekt-Konfiguration
  doctor                                          Repo untersuchen, Konfiguration vorschlagen

  --version    Version ausgeben
  help         Diese Hilfe
EOF
}

main() {
  (( $# == 0 )) && { wt_help; exit 2 }

  case $1 in
    --version|-V) print -- "wt $WT_VERSION"; return 0 ;;
    help|--help|-h) wt_help; return 0 ;;
    new|ls|up|down|rm|prune|ports|config|doctor)
      wt_die "noch nicht implementiert: $1" ;;
    *) wt_usage_die "unbekanntes Subkommando: $1" ;;
  esac
}

main "$@"
```

- [ ] **Step 8: Ausführbar machen und Syntax prüfen**

```bash
chmod +x bin/wt
zsh -n bin/wt && zsh -n lib/util.zsh && echo "Syntax ok"
```

Expected: `Syntax ok`

- [ ] **Step 9: Tests laufen lassen**

Run: `bats tests/cli.bats`
Expected: 4 Tests PASS

- [ ] **Step 10: herdr-Agent-Skill installieren**

```bash
mkdir -p ~/.claude/skills/herdr
herdr --skill > ~/.claude/skills/herdr/SKILL.md
head -3 ~/.claude/skills/herdr/SKILL.md
```

Expected: die Ausgabe beginnt mit `---` und `name: herdr`.

Das liegt bewusst außerhalb der Dotfiles: die Datei ist versionsgebunden an das installierte Binary und wird bei einem herdr-Update mit demselben Kommando neu erzeugt. Ein eingecheckter Stand würde veralten, ohne dass es auffällt.

- [ ] **Step 11: Commit**

```bash
git add .gitignore bin/wt lib/util.zsh tests/
git commit -m "feat: scaffold the wt command with a bats harness"

# Der Brewfile-Eintrag gehört zum anderen Repo:
git -C ~/dotfiles add Brewfile
git -C ~/dotfiles commit -m "brew: add bats-core for the wt test suite"
```

---

### Task 2: Konfiguration auflösen

**Files:**
- Create: `lib/config.zsh`
- Create: `tests/config.bats`
- Modify: `bin/wt` (Subkommando `config show`)

**Interfaces:**
- Consumes: `wt_die`, `wt_json_get` aus `util.zsh`
- Produces:
  - `wt_repo_root` → absoluter Pfad des Haupt-Checkouts (funktioniert auch aus einem Worktree heraus), Exit 1 außerhalb eines Repos
  - `wt_repo_name` → Basename davon
  - `wt_config_path` → erwarteter Pfad der Konfigurationsdatei (existiert nicht zwangsläufig)
  - `wt_config_load` → vollständiges JSON auf stdout, Vorgabewerte mit Benutzerdatei überlagert

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`tests/config.bats`:

```bash
#!/usr/bin/env bats

load helper

setup() {
  wt_tmpdirs
  wt_fixture_repo
  cd "$WT_REPO"
}
teardown() { wt_cleanup; }

@test "ohne Konfigurationsdatei greifen die Vorgabewerte" {
  run wt config show --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .base)" = "main" ]
  [ "$(echo "$output" | jq -r .ports.mode)" = "none" ]
  [ "$(echo "$output" | jq -r .branch_pattern)" = '{type}/{ticket}-{slug}' ]
  [ "$(echo "$output" | jq -r '.setup | length')" = "0" ]
}

@test "Benutzerdatei überlagert die Vorgabewerte" {
  cat > "$WT_CONFIG_DIR/projekt.json" <<'JSON'
{
  "base": "develop",
  "setup": ["npm ci"],
  "ports": { "mode": "env", "vars": { "VITE_PORT": 5173 } }
}
JSON
  run wt config show --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .base)" = "develop" ]
  [ "$(echo "$output" | jq -r '.setup[0]')" = "npm ci" ]
  [ "$(echo "$output" | jq -r .ports.vars.VITE_PORT)" = "5173" ]
  # Nicht gesetzte Schlüssel behalten den Vorgabewert
  [ "$(echo "$output" | jq -r .branch_pattern)" = '{type}/{ticket}-{slug}' ]
}

@test "ungültiges JSON wird mit Pfadangabe abgelehnt" {
  echo '{ kaputt' > "$WT_CONFIG_DIR/projekt.json"
  run wt config show --json
  [ "$status" -eq 1 ]
  [[ "$output" == *"ungültiges JSON"* ]]
  [[ "$output" == *"projekt.json"* ]]
}

@test "außerhalb eines Git-Repos bricht es mit Klartext ab" {
  cd "$WT_TMP"
  run wt config show --json
  [ "$status" -eq 1 ]
  [[ "$output" == *"kein Git-Repository"* ]]
}

@test "aus einem Worktree heraus wird der Name des Haupt-Repos gefunden" {
  git -C "$WT_REPO" worktree add -q "$WT_TMP/wt-abc" -b abc develop
  cd "$WT_TMP/wt-abc"
  cat > "$WT_CONFIG_DIR/projekt.json" <<'JSON'
{ "base": "develop" }
JSON
  run wt config show --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .base)" = "develop" ]
}
```

Der letzte Test ist der wichtigste: aus einem Worktree gibt `git rev-parse --show-toplevel` den *Worktree*-Pfad zurück, dessen Basename der Slug ist — damit würde die Konfiguration nicht gefunden. Deshalb wird `--git-common-dir` benutzt.

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/config.bats`
Expected: FAIL — alle fünf, `noch nicht implementiert: config`

- [ ] **Step 3: `config.zsh` schreiben**

`lib/config.zsh`:

```zsh
# Projekt-Konfiguration finden, laden und mit Vorgabewerten mischen.

# Haupt-Checkout, auch wenn wir in einem Worktree stehen.
# --git-common-dir zeigt immer auf das .git des Haupt-Repos.
wt_repo_root() {
  local common
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) \
    || wt_die "kein Git-Repository: $PWD"
  printf '%s\n' "${common:h}"
}

wt_repo_name() {
  local root
  root=$(wt_repo_root) || return 1
  printf '%s\n' "${root:t}"
}

wt_config_dir() {
  printf '%s\n' "${WT_CONFIG_DIR:-$HOME/.config/wt}"
}

wt_config_path() {
  local name
  name=$(wt_repo_name) || return 1
  printf '%s\n' "$(wt_config_dir)/${name}.json"
}

wt_config_defaults() {
  cat <<'JSON'
{
  "base": "main",
  "branch_pattern": "{type}/{ticket}-{slug}",
  "cwd": null,
  "setup": [],
  "teardown": [],
  "tabs": [ { "name": "claude" } ],
  "ports": { "mode": "none", "vars": {} }
}
JSON
}

# Vollständige Konfiguration auf stdout. Flache Überlagerung: ein vom Benutzer
# gesetzter Schlüssel ersetzt den Vorgabewert ganz, nicht teilweise.
wt_config_load() {
  local cfg_path defaults user
  cfg_path=$(wt_config_path) || return 1
  defaults=$(wt_config_defaults)

  if [[ ! -f $cfg_path ]]; then
    printf '%s\n' "$defaults" | jq -c \
      --arg repo "$(wt_repo_root)" '. + {repo: $repo, config_path: null}'
    return 0
  fi

  jq -e . "$cfg_path" >/dev/null 2>&1 \
    || wt_die "ungültiges JSON in $cfg_path"

  user=$(cat "$cfg_path")
  # Achtung: $path im jq-Programm ist die von --arg gebundene jq-Variable,
  # keine Shell-Variable.
  jq -c -n --argjson d "$defaults" --argjson u "$user" \
    --arg repo "$(wt_repo_root)" --arg path "$cfg_path" \
    '$d * $u + {repo: $repo, config_path: $path}'
}
```

- [ ] **Step 4: `config show` in `wt` verdrahten**

In `bin/wt` die `source`-Zeilen ergänzen:

```zsh
source "$WT_LIB/util.zsh"
source "$WT_LIB/config.zsh"
```

Den `case`-Zweig `new|ls|...` aufteilen, sodass `config` echt behandelt wird:

```zsh
    config)
      shift
      cmd_config "$@" ;;
    new|ls|up|down|rm|prune|ports|doctor)
      wt_die "noch nicht implementiert: $1" ;;
```

Und vor `main()` einfügen:

```zsh
cmd_config() {
  local sub=${1:-show}
  [[ $sub == show ]] || wt_usage_die "unbekanntes config-Subkommando: $sub"
  shift 2>/dev/null || true

  local json
  json=$(wt_config_load) || return 1

  if [[ " $* " == *" --json "* ]]; then
    printf '%s\n' "$json"
  else
    printf '%s\n' "$json" | jq .
  fi
}
```

- [ ] **Step 5: Tests laufen lassen**

Run: `bats tests/config.bats`
Expected: 5 Tests PASS

- [ ] **Step 6: Syntax prüfen und committen**

```bash
zsh -n bin/wt && zsh -n lib/config.zsh
git add bin/wt lib/config.zsh tests/config.bats
git commit -m "feat: resolve per-repo configuration with defaults"
```

---

### Task 3: Port-Zuteilung und Zustandsdatei

**Files:**
- Create: `lib/ports.zsh`
- Create: `lib/state.zsh`
- Create: `tests/ports.bats`
- Modify: `bin/wt` (Subkommando `ports`)

**Interfaces:**
- Consumes: `wt_die`, `wt_config_load`, `wt_repo_name`
- Produces:
  - `wt_offset_seed <slug>` → Ganzzahl 1–40
  - `wt_port_is_free <port>` → Exit 0 wenn frei
  - `wt_ports_alloc <slug> <config-json>` → JSON `{"offset":N,"ports":{"VAR":port,…}}`; bereits zugeteilte Werte werden unverändert wiederverwendet
  - `wt_state_path <slug>`, `wt_state_read <slug>`, `wt_state_write <slug> <json>`, `wt_state_delete <slug>`, `wt_state_list`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`tests/ports.bats`:

```bash
#!/usr/bin/env bats

load helper

setup() {
  wt_tmpdirs
  wt_fixture_repo
  cd "$WT_REPO"
  cat > "$WT_CONFIG_DIR/projekt.json" <<'JSON'
{
  "base": "develop",
  "ports": { "mode": "env",
             "vars": { "APP_PORT": 8080, "VITE_PORT": 5173, "DB_PORT": 5432 } }
}
JSON
}
teardown() { wt_cleanup; }

@test "Offset ist deterministisch aus dem Slug" {
  # cksum("PROJ-1234") = 3180234491 -> 3180234491 % 40 + 1 = 12
  run wt ports PROJ-1234 --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .offset)" = "12" ]
  [ "$(echo "$output" | jq -r .ports.APP_PORT)" = "8092" ]
  [ "$(echo "$output" | jq -r .ports.VITE_PORT)" = "5185" ]
  [ "$(echo "$output" | jq -r .ports.DB_PORT)" = "5444" ]
}

@test "verschiedene Slugs erhalten verschiedene Offsets" {
  # cksum("PROJ-9999") = 1979397512 -> Offset 33
  run wt ports PROJ-9999 --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .offset)" = "33" ]
}

@test "zweiter Aufruf liefert exakt dieselben Ports" {
  run wt ports PROJ-1234 --json
  first="$output"
  run wt ports PROJ-1234 --json
  [ "$output" = "$first" ]
}

@test "belegter Port rückt den Offset weiter" {
  # Offset 12 belegen: APP_PORT 8092
  nc -l 127.0.0.1 8092 >/dev/null 2>&1 &
  local listener=$!
  # Warten bis der Listener steht
  for _ in $(seq 1 20); do nc -z 127.0.0.1 8092 && break; sleep 0.1; done

  run wt ports PROJ-1234 --json
  kill "$listener" 2>/dev/null || true

  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .offset)" != "12" ]
}

@test "Zustandsdatei wird angelegt und enthält den Offset" {
  run wt ports PROJ-1234 --json
  [ "$status" -eq 0 ]
  [ -f "$WT_STATE_DIR/projekt/PROJ-1234.json" ]
  [ "$(jq -r .offset "$WT_STATE_DIR/projekt/PROJ-1234.json")" = "12" ]
}

@test "bei mode=none werden keine Ports zugeteilt" {
  echo '{ "base": "develop" }' > "$WT_CONFIG_DIR/projekt.json"
  run wt ports PROJ-1234 --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.ports | length')" = "0" ]
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/ports.bats`
Expected: FAIL — `noch nicht implementiert: ports`

- [ ] **Step 3: `state.zsh` schreiben**

`lib/state.zsh`:

```zsh
# Zustand pro Worktree: gewählter Offset, Ports, Pfade, herdr-IDs.

wt_state_dir() {
  local name
  name=$(wt_repo_name) || return 1
  printf '%s\n' "${WT_STATE_DIR:-$HOME/.local/state/wt}/$name"
}

wt_state_path() {
  local slug=$1 dir
  dir=$(wt_state_dir) || return 1
  printf '%s\n' "$dir/${slug}.json"
}

wt_state_read() {
  local wt_path
  wt_path=$(wt_state_path "$1") || return 1
  [[ -f $wt_path ]] || return 1
  cat "$wt_path"
}

wt_state_write() {
  local slug=$1 json=$2 path
  wt_path=$(wt_state_path "$slug") || return 1
  mkdir -p "${wt_path:h}"
  printf '%s\n' "$json" | jq -c . > "$wt_path"
}

# Führt die Zustandsdatei mit einem JSON-Fragment zusammen.
wt_state_merge() {
  local slug=$1 fragment=$2 current
  current=$(wt_state_read "$slug" 2>/dev/null) || current='{}'
  wt_state_write "$slug" \
    "$(jq -c -n --argjson a "$current" --argjson b "$fragment" '$a * $b')"
}

wt_state_delete() {
  local wt_path
  wt_path=$(wt_state_path "$1") || return 1
  rm -f "$wt_path"
}

# Slugs aller bekannten Worktrees, einer pro Zeile.
wt_state_list() {
  local dir
  dir=$(wt_state_dir) || return 1
  [[ -d $dir ]] || return 0
  local f
  for f in "$dir"/*.json(N); do
    printf '%s\n' "${${f:t}:r}"
  done
}
```

- [ ] **Step 4: `ports.zsh` schreiben**

`lib/ports.zsh`:

```zsh
# Deterministische, kollisionsfreie Port-Zuteilung pro Worktree.

typeset -gi WT_OFFSET_MAX=40

wt_offset_seed() {
  local slug=$1 sum
  sum=$(printf '%s' "$slug" | cksum | awk '{print $1}')
  printf '%d\n' $(( sum % WT_OFFSET_MAX + 1 ))
}

# Exit 0 = Port ist frei. nc -z liefert 0, wenn ein Listener antwortet.
# Kein -G/-w ergänzen: damit liefert nc auch bei belegtem Port 1.
wt_port_is_free() {
  ! nc -z 127.0.0.1 "$1" >/dev/null 2>&1
}

# Sind alle Ports für diesen Offset frei?
wt_offset_is_free() {
  local -i offset=$1
  shift
  local -i base
  for base in "$@"; do
    wt_port_is_free $(( base + offset )) || return 1
  done
  return 0
}

# wt_ports_alloc <slug> <config-json> -> {"offset":N,"ports":{...}}
# Ein bereits festgeschriebener Offset wird ohne Prüfung wiederverwendet:
# stabile Ports sind wichtiger als eine erneute Kollisionsprüfung.
wt_ports_alloc() {
  local slug=$1 config=$2
  local mode names bases state
  mode=$(printf '%s' "$config" | jq -r '.ports.mode // "none"')

  if [[ $mode == none ]]; then
    printf '{"offset":0,"ports":{}}\n'
    return 0
  fi

  local -a var_names var_bases
  var_names=(${(f)"$(printf '%s' "$config" | jq -r '.ports.vars | keys_unsorted[]')"})
  var_bases=(${(f)"$(printf '%s' "$config" | jq -r '.ports.vars[]')"})

  if (( ${#var_names} == 0 )); then
    printf '{"offset":0,"ports":{}}\n'
    return 0
  fi

  local -i offset=0
  state=$(wt_state_read "$slug" 2>/dev/null) || state=''
  if [[ -n $state ]]; then
    offset=$(printf '%s' "$state" | jq -r '.offset // 0')
  fi

  if (( offset == 0 )); then
    local -i seed try i
    seed=$(wt_offset_seed "$slug")
    for (( i = 0; i < WT_OFFSET_MAX; i++ )); do
      try=$(( (seed - 1 + i) % WT_OFFSET_MAX + 1 ))
      if wt_offset_is_free $try "${var_bases[@]}"; then
        offset=$try
        break
      fi
    done
    (( offset == 0 )) && wt_die \
      "keine freie Port-Kombination gefunden (Offsets 1-$WT_OFFSET_MAX alle belegt)"
  fi

  local result i
  result=$(jq -c -n --argjson o "$offset" '{offset: $o, ports: {}}')
  for (( i = 1; i <= ${#var_names}; i++ )); do
    result=$(printf '%s' "$result" | jq -c \
      --arg k "${var_names[i]}" \
      --argjson v $(( var_bases[i] + offset )) \
      '.ports[$k] = $v')
  done

  wt_state_merge "$slug" "$result"
  printf '%s\n' "$result"
}
```

- [ ] **Step 5: `ports` in `wt` verdrahten**

`source`-Zeilen ergänzen:

```zsh
source "$WT_LIB/state.zsh"
source "$WT_LIB/ports.zsh"
```

`case`-Zweig:

```zsh
    ports)
      shift
      cmd_ports "$@" ;;
```

Funktion:

```zsh
cmd_ports() {
  local slug=${1:-}
  [[ -n $slug ]] || wt_usage_die "wt ports <slug> [--json]"
  shift

  local config result
  config=$(wt_config_load) || return 1
  result=$(wt_ports_alloc "$slug" "$config") || return 1

  if [[ " $* " == *" --json "* ]]; then
    printf '%s\n' "$result"
    return 0
  fi

  print -- "Worktree: $slug   Offset: $(printf '%s' "$result" | jq -r .offset)"
  local k v
  printf '%s' "$result" | jq -r '.ports | to_entries[] | "\(.key)=\(.value)"' \
    | while IFS='=' read -r k v; do
        if wt_port_is_free "$v"; then
          print -- "  $k=$v   http://localhost:$v"
        else
          print -- "  $k=$v   http://localhost:$v   (aktuell belegt)"
        fi
      done
}
```

- [ ] **Step 6: Tests laufen lassen**

Run: `bats tests/ports.bats`
Expected: 6 Tests PASS

- [ ] **Step 7: Syntax prüfen und committen**

```bash
zsh -n bin/wt && zsh -n lib/ports.zsh && zsh -n lib/state.zsh
git add bin/wt lib/{ports,state}.zsh tests/ports.bats
git commit -m "feat: allocate deterministic per-worktree ports"
```

---

### Task 4: `.env`-Block und Compose-Override

**Files:**
- Create: `lib/envfile.zsh`
- Create: `tests/envfile.bats`

**Interfaces:**
- Consumes: `wt_die`, `wt_warn`
- Produces:
  - `wt_env_write <worktree-pfad> <ports-json>` → schreibt den markierten Block in `<pfad>/.env`, idempotent
  - `wt_compose_override_write <worktree-pfad> <config-json> <ports-json>` → schreibt `docker-compose.override.yml`
  - `wt_compose_supports_override` → Exit 0 wenn Docker Compose ≥ 2.24

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`tests/envfile.bats`:

```bash
#!/usr/bin/env bats

load helper

setup() {
  wt_tmpdirs
  export WT_WT="$WT_TMP/worktree"
  mkdir -p "$WT_WT"
  # Direktes Sourcen der Bibliothek über einen zsh-Einzeiler
  wt_env_write() {
    zsh -c "source $WT_LIB/util.zsh; source $WT_LIB/envfile.zsh; wt_env_write \"\$1\" \"\$2\"" _ "$@"
  }
  wt_override_write() {
    zsh -c "source $WT_LIB/util.zsh; source $WT_LIB/envfile.zsh; wt_compose_override_write \"\$1\" \"\$2\" \"\$3\"" _ "$@"
  }
}
teardown() { wt_cleanup; }

@test "Block wird in eine neue .env geschrieben" {
  run wt_env_write "$WT_WT" '{"ports":{"VITE_PORT":5185}}'
  [ "$status" -eq 0 ]
  grep -q '^# >>> wt$'        "$WT_WT/.env"
  grep -q '^VITE_PORT=5185$'  "$WT_WT/.env"
  grep -q '^# <<< wt$'        "$WT_WT/.env"
}

@test "bestehende Zeilen bleiben erhalten" {
  printf 'APP_ENV=local\nSECRET=abc\n' > "$WT_WT/.env"
  run wt_env_write "$WT_WT" '{"ports":{"VITE_PORT":5185}}'
  [ "$status" -eq 0 ]
  grep -q '^APP_ENV=local$' "$WT_WT/.env"
  grep -q '^SECRET=abc$'    "$WT_WT/.env"
}

@test "zweiter Schreibvorgang ersetzt den Block statt ihn zu verdoppeln" {
  wt_env_write "$WT_WT" '{"ports":{"VITE_PORT":5185}}'
  wt_env_write "$WT_WT" '{"ports":{"VITE_PORT":5199}}'
  [ "$(grep -c '^# >>> wt$'      "$WT_WT/.env")" -eq 1 ]
  [ "$(grep -c '^VITE_PORT='     "$WT_WT/.env")" -eq 1 ]
  grep -q '^VITE_PORT=5199$' "$WT_WT/.env"
}

@test "Override-Datei benutzt das !override-Tag" {
  cfg='{"ports":{"mode":"override","services":{"client":[{"host":5173,"container":5173}]}}}'
  run wt_override_write "$WT_WT" "$cfg" '{"offset":12,"ports":{}}'
  [ "$status" -eq 0 ]
  grep -q 'ports: !override' "$WT_WT/docker-compose.override.yml"
  # host 5173 + offset 12 = 5185, Container-Port bleibt
  grep -q '"5185:5173"'      "$WT_WT/docker-compose.override.yml"
  grep -q '^  client:'       "$WT_WT/docker-compose.override.yml"
}

@test "bei mode=env wird keine Override-Datei erzeugt" {
  cfg='{"ports":{"mode":"env","vars":{"VITE_PORT":5173}}}'
  run wt_override_write "$WT_WT" "$cfg" '{"offset":12,"ports":{"VITE_PORT":5185}}'
  [ "$status" -eq 0 ]
  [ ! -f "$WT_WT/docker-compose.override.yml" ]
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/envfile.bats`
Expected: FAIL — `envfile.zsh` existiert nicht

- [ ] **Step 3: `envfile.zsh` schreiben**

`lib/envfile.zsh`:

```zsh
# Worktree-lokale Dateien für Port-Isolation: .env-Block und Compose-Override.

typeset -g WT_ENV_BEGIN='# >>> wt'
typeset -g WT_ENV_END='# <<< wt'

# Schreibt die Ports als markierten Block in <worktree>/.env.
# Vorhandener Block wird ersetzt, alles andere bleibt unberührt.
wt_env_write() {
  local dir=$1 ports_json=$2
  local envfile="$dir/.env"
  local -a lines
  lines=(${(f)"$(printf '%s' "$ports_json" \
    | jq -r '.ports | to_entries[] | "\(.key)=\(.value)"')"})

  local kept=''
  if [[ -f $envfile ]]; then
    kept=$(awk -v b="$WT_ENV_BEGIN" -v e="$WT_ENV_END" '
      $0 == b { skip = 1; next }
      $0 == e { skip = 0; next }
      !skip   { print }
    ' "$envfile")
  fi

  {
    [[ -n $kept ]] && printf '%s\n' "$kept"
    printf '%s\n' "$WT_ENV_BEGIN"
    local l
    for l in "${lines[@]}"; do
      [[ -n $l ]] && printf '%s\n' "$l"
    done
    printf '%s\n' "$WT_ENV_END"
  } > "$envfile.tmp"
  mv "$envfile.tmp" "$envfile"
}

# Exit 0, wenn Docker Compose das !override-Tag versteht (ab 2.24).
wt_compose_supports_override() {
  local v major minor
  v=$(docker compose version --short 2>/dev/null) || return 1
  v=${v#v}
  major=${v%%.*}
  minor=${${v#*.}%%.*}
  (( major > 2 || (major == 2 && minor >= 24) ))
}

# Erzeugt docker-compose.override.yml, wenn ports.mode == "override".
# Ohne !override würde Compose die ports-Liste anhängen statt sie zu ersetzen —
# das alte, kollidierende Binding bliebe bestehen.
wt_compose_override_write() {
  local dir=$1 config=$2 ports_json=$3
  local mode offset
  mode=$(printf '%s' "$config" | jq -r '.ports.mode // "none"')
  [[ $mode == override ]] || return 0

  wt_compose_supports_override || wt_warn \
    "Docker Compose < 2.24: !override wirkt nicht, Port-Kollisionen bleiben möglich"

  offset=$(printf '%s' "$ports_json" | jq -r '.offset // 0')

  {
    print -- "# Von wt erzeugt. Nicht von Hand bearbeiten."
    print -- "services:"
    printf '%s' "$config" | jq -r --argjson off "$offset" '
      .ports.services | to_entries[] |
      "  \(.key):\n    ports: !override [" +
      ([ .value[] | "\"\(.host + $off):\(.container)\"" ] | join(", ")) +
      "]"
    '
  } > "$dir/docker-compose.override.yml"
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `bats tests/envfile.bats`
Expected: 5 Tests PASS

- [ ] **Step 5: Syntax prüfen und committen**

```bash
zsh -n lib/envfile.zsh
git add lib/envfile.zsh tests/envfile.bats
git commit -m "feat: write per-worktree env block and compose override"
```

---

### Task 5: Git-Schicht

**Files:**
- Create: `lib/git.zsh`
- Create: `tests/git.bats`

**Interfaces:**
- Consumes: `wt_die`, `wt_warn`, `wt_repo_root`
- Produces:
  - `wt_base_update <repo> <base>` → holt den Basis-Branch, wenn ein Remote existiert; Exit 1 wenn der Ref fehlt
  - `wt_worktree_path <slug>` → `${WT_WORKTREE_DIR:-$HOME/.herdr/worktrees}/<repo>/<slug>`
  - `wt_worktree_create <repo> <slug> <branch> <base>` → Pfad auf stdout; existiert der Branch schon, wird der bestehende Worktree geöffnet statt zu scheitern
  - `wt_worktree_is_dirty <pfad>` → Exit 0 wenn uncommittete Änderungen
  - `wt_worktree_remove <repo> <pfad>`
  - `wt_worktree_merged <repo> <base>` → Branches, die in `<base>` gemergt sind, einer pro Zeile
  - `wt_git_exclude <pfad> <muster>` → Eintrag in `.git/info/exclude` des Worktrees, idempotent

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`tests/git.bats`:

```bash
#!/usr/bin/env bats

load helper

setup() {
  wt_tmpdirs
  wt_fixture_repo
  zsh_lib() {
    zsh -c "source $WT_LIB/util.zsh; source $WT_LIB/config.zsh; source $WT_LIB/git.zsh; $1" _ "${@:2}"
  }
}
teardown() { wt_cleanup; }

@test "fehlender Basis-Branch wird vor dem Anlegen abgelehnt" {
  run zsh_lib 'wt_base_update "$1" "$2"' "$WT_REPO" gibtsnicht
  [ "$status" -eq 1 ]
  [[ "$output" == *"Basis-Branch nicht gefunden"* ]]
  [[ "$output" == *"gibtsnicht"* ]]
}

@test "ohne Remote ist das Aktualisieren ein Erfolg mit Hinweis" {
  run zsh_lib 'wt_base_update "$1" "$2"' "$WT_REPO" develop
  [ "$status" -eq 0 ]
}

@test "Worktree wird angelegt und der Branch zeigt auf die Basis" {
  run zsh_lib 'wt_worktree_create "$1" "$2" "$3" "$4"' \
    "$WT_REPO" PROJ-1 bugfix/PROJ-1 develop
  [ "$status" -eq 0 ]
  path="$output"
  [ -d "$path" ]
  [ "$(git -C "$path" rev-parse --abbrev-ref HEAD)" = "bugfix/PROJ-1" ]
  [ "$(git -C "$path" rev-parse HEAD)" = "$(git -C "$WT_REPO" rev-parse develop)" ]
}

@test "bestehender Branch wird geöffnet statt abgelehnt" {
  zsh_lib 'wt_worktree_create "$1" "$2" "$3" "$4"' \
    "$WT_REPO" PROJ-1 bugfix/PROJ-1 develop
  run zsh_lib 'wt_worktree_create "$1" "$2" "$3" "$4"' \
    "$WT_REPO" PROJ-1 bugfix/PROJ-1 develop
  [ "$status" -eq 0 ]
  [ -d "$output" ]
  [ "$(git -C "$output" rev-parse --abbrev-ref HEAD)" = "bugfix/PROJ-1" ]
}

@test "uncommittete Änderungen werden erkannt" {
  path=$(zsh_lib 'wt_worktree_create "$1" "$2" "$3" "$4"' \
    "$WT_REPO" PROJ-1 bugfix/PROJ-1 develop)
  run zsh_lib 'wt_worktree_is_dirty "$1"' "$path"
  [ "$status" -eq 1 ]
  echo aenderung >> "$path/README.md"
  run zsh_lib 'wt_worktree_is_dirty "$1"' "$path"
  [ "$status" -eq 0 ]
}

@test "gemergte Branches werden gefunden, ungemergte nicht" {
  git -C "$WT_REPO" checkout -q -b fertig develop
  echo x > "$WT_REPO/x.txt"
  git -C "$WT_REPO" add -A && git -C "$WT_REPO" commit -qm x
  git -C "$WT_REPO" checkout -q develop
  git -C "$WT_REPO" merge -q --no-ff -m merge fertig
  git -C "$WT_REPO" checkout -q -b offen develop
  echo y > "$WT_REPO/y.txt"
  git -C "$WT_REPO" add -A && git -C "$WT_REPO" commit -qm y
  git -C "$WT_REPO" checkout -q develop

  run zsh_lib 'wt_worktree_merged "$1" "$2"' "$WT_REPO" develop
  [ "$status" -eq 0 ]
  [[ "$output" == *fertig* ]]
  [[ "$output" != *offen* ]]
}

@test "exclude-Eintrag landet in .git/info/exclude und verdoppelt sich nicht" {
  path=$(zsh_lib 'wt_worktree_create "$1" "$2" "$3" "$4"' \
    "$WT_REPO" PROJ-1 bugfix/PROJ-1 develop)
  zsh_lib 'wt_git_exclude "$1" "$2"' "$path" '.wt/'
  zsh_lib 'wt_git_exclude "$1" "$2"' "$path" '.wt/'
  excl="$(git -C "$path" rev-parse --git-path info/exclude)"
  [ "$(grep -c '^\.wt/$' "$excl")" -eq 1 ]
  # Die .gitignore des Projekts bleibt unangetastet
  [ ! -f "$path/.gitignore" ]
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/git.bats`
Expected: FAIL — `git.zsh` existiert nicht

- [ ] **Step 3: `git.zsh` schreiben**

`lib/git.zsh`:

```zsh
# Git-Operationen: Basis aktualisieren, Worktrees anlegen und entfernen.

# Holt den Basis-Branch, falls ein Remote existiert, und stellt sicher,
# dass der Ref überhaupt vorhanden ist. Schlägt das fehl, wird nichts angelegt.
wt_base_update() {
  local repo=$1 base=$2
  if git -C "$repo" remote | grep -q .; then
    local remote
    remote=$(git -C "$repo" remote | head -1)
    git -C "$repo" fetch -q "$remote" "$base" 2>/dev/null \
      || wt_warn "konnte $base nicht von $remote holen, benutze den lokalen Stand"
  fi
  git -C "$repo" rev-parse --verify --quiet "refs/heads/$base" >/dev/null \
    || git -C "$repo" rev-parse --verify --quiet "$base" >/dev/null \
    || wt_die "Basis-Branch nicht gefunden: $base"
}

wt_worktree_root() {
  printf '%s\n' "${WT_WORKTREE_DIR:-$HOME/.herdr/worktrees}"
}

wt_worktree_path() {
  local repo=$1 slug=$2
  printf '%s\n' "$(wt_worktree_root)/${repo:t}/$slug"
}

# Legt den Worktree an. Existiert der Branch bereits, wird er ausgecheckt
# statt neu erzeugt; existiert der Worktree bereits, wird nur der Pfad
# zurückgegeben. Beides ist kein Fehler, sondern Fortsetzen der Arbeit.
wt_worktree_create() {
  local repo=$1 slug=$2 branch=$3 base=$4
  local wt_path
  wt_path=$(wt_worktree_path "$repo" "$slug")

  if [[ -d $wt_path ]]; then
    printf '%s\n' "$wt_path"
    return 0
  fi
  mkdir -p "${wt_path:h}"

  if git -C "$repo" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
    git -C "$repo" worktree add -q "$wt_path" "$branch" \
      || wt_die "worktree add fehlgeschlagen für bestehenden Branch $branch"
  else
    git -C "$repo" worktree add -q -b "$branch" "$wt_path" "$base" \
      || wt_die "worktree add fehlgeschlagen für neuen Branch $branch von $base"
  fi
  printf '%s\n' "$wt_path"
}

wt_worktree_is_dirty() {
  local wt_path=$1
  [[ -n $(git -C "$wt_path" status --porcelain 2>/dev/null) ]]
}

wt_worktree_remove() {
  local repo=$1 wt_path=$2
  git -C "$repo" worktree remove --force "$wt_path" \
    || wt_die "worktree remove fehlgeschlagen: $wt_path"
  git -C "$repo" worktree prune
}

# Branches, die vollständig in <base> enthalten sind. Ohne base selbst.
wt_worktree_merged() {
  local repo=$1 base=$2
  git -C "$repo" branch --merged "$base" --format '%(refname:short)' \
    | grep -v -x "$base" || true
}

# Idempotenter Eintrag in die worktree-eigene Ausschlussliste.
# Bewusst .git/info/exclude und nicht .gitignore: im Firmen-Repo wird
# keine eingecheckte Datei verändert.
wt_git_exclude() {
  local wt_path=$1 pattern=$2 excl
  excl=$(git -C "$wt_path" rev-parse --git-path info/exclude) || return 1
  [[ $excl == /* ]] || excl="$wt_path/$excl"
  mkdir -p "${excl:h}"
  touch "$excl"
  grep -q -x -F "$pattern" "$excl" || printf '%s\n' "$pattern" >> "$excl"
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `bats tests/git.bats`
Expected: 7 Tests PASS

- [ ] **Step 5: Syntax prüfen und committen**

```bash
zsh -n lib/git.zsh
git add lib/git.zsh tests/git.bats
git commit -m "feat: add the git worktree layer"
```

---

### Task 6: herdr-Schicht

**Files:**
- Create: `lib/herdr.zsh`
- Create: `tests/herdr.bats`

**Interfaces:**
- Consumes: `wt_die`, `wt_warn`, `wt_json_get`
- Produces:
  - `wt_herdr_bin` → `${WT_HERDR_BIN:-herdr}`
  - `wt_herdr_available` → Exit 0 wenn das Binary da ist **und** der Server antwortet
  - `wt_herdr_call <args…>` → JSON auf stdout, Exit 1 mit Klartext bei Fehler
  - `wt_herdr_build <worktree-pfad> <workdir> <label> <branch> <base> <config-json> <ports-json>` → JSON `{"workspace_id":…,"agent_pane":…}`. Getrennte Pfade mit Absicht: der Worktree entsteht unter `<worktree-pfad>`, Tabs und Panes starten in `<workdir>` (identisch, außer bei gesetztem `cwd`).

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`tests/herdr.bats`:

```bash
#!/usr/bin/env bats

load helper

setup() {
  wt_tmpdirs
  wt_stub_herdr
  export WT_WT="$WT_TMP/worktree"
  mkdir -p "$WT_WT"
  zsh_lib() {
    zsh -c "source $WT_LIB/util.zsh; source $WT_LIB/herdr.zsh; $1" _ "${@:2}"
  }
}
teardown() { wt_cleanup; }

CFG='{"tabs":[
  {"name":"claude"},
  {"name":"edit","command":"nvim"},
  {"name":"stack","panes":[
    {"name":"server","command":"npm run dev"},
    {"name":"client","command":"npm start","direction":"right"}]}]}'

@test "Workspace wird über worktree create mit --no-focus angelegt" {
  # Pfad zweimal: hier sind Worktree-Wurzel und Arbeitsverzeichnis identisch
  run zsh_lib 'wt_herdr_build "$1" "$1" "$2" "$3" "$4" "$5" "$6"' \
    "$WT_WT" projekt-PROJ-1 bugfix/PROJ-1 develop "$CFG" '{"ports":{}}'
  [ "$status" -eq 0 ]
  grep -q 'worktree create' "$WT_HERDR_LOG"
  grep -q -- '--no-focus'   "$WT_HERDR_LOG"
  [ "$(echo "$output" | jq -r .workspace_id)" = "w9" ]
}

@test "der erste Tab bleibt am Prompt und wird als Agent-Pane gemeldet" {
  # Pfad zweimal: hier sind Worktree-Wurzel und Arbeitsverzeichnis identisch
  run zsh_lib 'wt_herdr_build "$1" "$1" "$2" "$3" "$4" "$5" "$6"' \
    "$WT_WT" projekt-PROJ-1 bugfix/PROJ-1 develop "$CFG" '{"ports":{}}'
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .agent_pane)" = "w9:p1" ]
  # In das Agent-Pane wird nichts hineingeschrieben
  ! grep -q 'pane run w9:p1' "$WT_HERDR_LOG"
}

@test "je konfiguriertem Tab wird ein Tab erzeugt, der erste ausgenommen" {
  # Pfad zweimal: hier sind Worktree-Wurzel und Arbeitsverzeichnis identisch
  run zsh_lib 'wt_herdr_build "$1" "$1" "$2" "$3" "$4" "$5" "$6"' \
    "$WT_WT" projekt-PROJ-1 bugfix/PROJ-1 develop "$CFG" '{"ports":{}}'
  [ "$(grep -c 'tab create' "$WT_HERDR_LOG")" -eq 2 ]
  grep -q 'edit'  "$WT_HERDR_LOG"
  grep -q 'stack' "$WT_HERDR_LOG"
}

@test "Tab-Kommando und Pane-Kommandos werden ausgeführt" {
  # Pfad zweimal: hier sind Worktree-Wurzel und Arbeitsverzeichnis identisch
  run zsh_lib 'wt_herdr_build "$1" "$1" "$2" "$3" "$4" "$5" "$6"' \
    "$WT_WT" projekt-PROJ-1 bugfix/PROJ-1 develop "$CFG" '{"ports":{}}'
  grep -q 'pane run w9:p2 nvim'        "$WT_HERDR_LOG"
  grep -q 'pane run w9:p2 npm run dev' "$WT_HERDR_LOG"
  grep -q 'pane split'                 "$WT_HERDR_LOG"
  grep -q 'pane run w9:p3 npm start'   "$WT_HERDR_LOG"
}

@test "zweites Pane wird in die konfigurierte Richtung gesplittet" {
  # Pfad zweimal: hier sind Worktree-Wurzel und Arbeitsverzeichnis identisch
  run zsh_lib 'wt_herdr_build "$1" "$1" "$2" "$3" "$4" "$5" "$6"' \
    "$WT_WT" projekt-PROJ-1 bugfix/PROJ-1 develop "$CFG" '{"ports":{}}'
  grep -q -- '--direction right' "$WT_HERDR_LOG"
}

@test "Ports wandern als --env in Tabs und Panes" {
  # Pfad zweimal: hier sind Worktree-Wurzel und Arbeitsverzeichnis identisch
  run zsh_lib 'wt_herdr_build "$1" "$1" "$2" "$3" "$4" "$5" "$6"' \
    "$WT_WT" projekt-PROJ-1 bugfix/PROJ-1 develop "$CFG" \
    '{"ports":{"VITE_PORT":5185}}'
  grep -q -- '--env VITE_PORT=5185'          "$WT_HERDR_LOG"
  grep -q -- '--env COMPOSE_PROJECT_NAME='   "$WT_HERDR_LOG"
}

@test "fehlender herdr-Server wird erkannt" {
  cat > "$WT_HERDR_BIN" <<'STUB'
#!/usr/bin/env bash
echo '{"error":"server not running"}' >&2
exit 1
STUB
  chmod +x "$WT_HERDR_BIN"
  run zsh_lib 'wt_herdr_available'
  [ "$status" -ne 0 ]
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/herdr.bats`
Expected: FAIL — `herdr.zsh` existiert nicht

- [ ] **Step 3: `herdr.zsh` schreiben**

`lib/herdr.zsh`:

```zsh
# Workspace, Tabs und Panes in herdr aufbauen.
# Alle IDs werden aus den JSON-Antworten gelesen, nie erraten.

wt_herdr_bin() {
  printf '%s\n' "${WT_HERDR_BIN:-herdr}"
}

wt_herdr_available() {
  local bin
  bin=$(wt_herdr_bin)
  whence -p "$bin" >/dev/null || [[ -x $bin ]] || return 1
  "$bin" workspace list >/dev/null 2>&1
}

wt_herdr_call() {
  local bin out
  bin=$(wt_herdr_bin)
  out=$("$bin" "$@" 2>&1) || wt_die "herdr $1 $2 fehlgeschlagen: $out"
  printf '%s\n' "$out"
}

# Baut Workspace und Layout auf.
# Der erste konfigurierte Tab ist der Agent-Tab: sein Root-Pane bleibt am
# Prompt, damit der Hub dort später einen Agent starten kann.
wt_herdr_build() {
  local wt_path=$1 workdir=$2 label=$3 branch=$4 base=$5 config=$6 ports=$7

  local -a envargs
  local k v
  while IFS='=' read -r k v; do
    [[ -n $k ]] && envargs+=(--env "$k=$v")
  done < <(printf '%s' "$ports" | jq -r '.ports | to_entries[] | "\(.key)=\(.value)"')
  envargs+=(--env "COMPOSE_PROJECT_NAME=$label")

  local resp workspace_id
  resp=$(wt_herdr_call worktree create \
    --branch "$branch" --base "$base" --path "$wt_path" \
    --label "$label" --no-focus) || return 1

  workspace_id=$(wt_json_get "$resp" '.result.workspace.workspace_id')
  if [[ -z $workspace_id ]]; then
    # Antwortform unbekannt: über das Label nachschlagen statt zu raten.
    workspace_id=$(wt_json_get \
      "$(wt_herdr_call workspace list)" \
      ".result.workspaces[] | select(.label == \"$label\") | .workspace_id")
  fi
  [[ -n $workspace_id ]] || wt_die "konnte die Workspace-ID nicht ermitteln"

  local agent_pane
  agent_pane=$(wt_json_get "$resp" '.result.root_pane.pane_id')

  local -i i n
  n=$(printf '%s' "$config" | jq -r '.tabs | length')
  for (( i = 0; i < n; i++ )); do
    local tab name cmd root
    tab=$(printf '%s' "$config" | jq -c ".tabs[$i]")
    name=$(printf '%s' "$tab" | jq -r '.name // "tab"')

    if (( i == 0 )); then
      # Agent-Tab: existiert bereits als Root-Tab des Workspace.
      continue
    fi

    local tresp
    tresp=$(wt_herdr_call tab create --workspace "$workspace_id" \
      --cwd "$workdir" --label "$name" "${envargs[@]}" --no-focus) || return 1
    root=$(wt_json_get "$tresp" '.result.root_pane.pane_id')
    [[ -n $root ]] || wt_die "konnte das Root-Pane von Tab $name nicht ermitteln"

    cmd=$(printf '%s' "$tab" | jq -r '.command // empty')
    [[ -n $cmd ]] && wt_herdr_call pane run "$root" ${=cmd} >/dev/null

    local -i p pn
    pn=$(printf '%s' "$tab" | jq -r '.panes | length // 0')
    local current=$root
    for (( p = 0; p < pn; p++ )); do
      local pane pcmd pdir target presp
      pane=$(printf '%s' "$tab" | jq -c ".panes[$p]")
      pcmd=$(printf '%s' "$pane" | jq -r '.command // empty')
      pdir=$(printf '%s' "$pane" | jq -r '.direction // "right"')

      if (( p == 0 )); then
        target=$root
      else
        presp=$(wt_herdr_call pane split --pane "$current" \
          --direction "$pdir" --cwd "$workdir" "${envargs[@]}" --no-focus) || return 1
        target=$(wt_json_get "$presp" '.result.pane.pane_id')
        [[ -n $target ]] || wt_die "konnte die Pane-ID nach dem Split nicht ermitteln"
      fi
      current=$target
      [[ -n $pcmd ]] && wt_herdr_call pane run "$target" ${=pcmd} >/dev/null
    done
  done

  jq -c -n --arg w "$workspace_id" --arg a "$agent_pane" \
    '{workspace_id: $w, agent_pane: $a}'
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `bats tests/herdr.bats`
Expected: 7 Tests PASS

- [ ] **Step 5: Syntax prüfen und committen**

```bash
zsh -n lib/herdr.zsh
git add lib/herdr.zsh tests/herdr.bats
git commit -m "feat: build herdr workspace layout from config"
```

---

### Task 7: `wt new` verdrahten, inklusive `--dry-run`

**Files:**
- Modify: `bin/wt`
- Create: `tests/new.bats`

**Interfaces:**
- Consumes: alles aus Task 2–6
- Produces:
  - `wt new <slug> [--base <ref>] [--type bugfix|feature] [--ticket <id>] [--dry-run] [--json]`; JSON-Felder `slug`, `branch`, `path`, `base`, `compose_project`, `ports`, `workspace_id`, `agent_pane`, `setup_ok`
  - `wt_branch_name <pattern> <type> <ticket> <slug>` → Branch-Name ohne leere Segmente
  - `wt_work_dir <pfad> <config-json>` → Arbeitsverzeichnis unter Beachtung von `cwd`
  - `wt_env_script_write <pfad> <ports-json> <label> <repo>` → schreibt `.wt/env.sh`
  - `wt_run_steps <dir> <label> <cmd…>` → führt Kommandos aus, bricht beim ersten Fehler ab

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`tests/new.bats`:

```bash
#!/usr/bin/env bats

load helper

setup() {
  wt_tmpdirs
  wt_fixture_repo
  wt_stub_herdr
  cd "$WT_REPO"
  cat > "$WT_CONFIG_DIR/projekt.json" <<'JSON'
{
  "base": "develop",
  "branch_pattern": "{type}/{ticket}-{slug}",
  "setup": ["echo setup-lief > setup.marker"],
  "teardown": ["echo teardown"],
  "tabs": [ {"name":"claude"}, {"name":"edit","command":"nvim"} ],
  "ports": { "mode": "env", "vars": { "VITE_PORT": 5173 } }
}
JSON
}
teardown() { wt_cleanup; }

@test "--dry-run fasst alles zusammen und verändert nichts" {
  run wt_json new login-bug --type bugfix --ticket PROJ-1234 --dry-run --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .branch)" = "bugfix/PROJ-1234-login-bug" ]
  [ "$(echo "$output" | jq -r .dry_run)" = "true" ]
  [ ! -d "$WT_WORKTREE_DIR/projekt/login-bug" ]
  [ ! -s "$WT_HERDR_LOG" ]
}

@test "fehlendes Ticket lässt kein leeres Segment im Branch" {
  run wt_json new login-bug --type bugfix --dry-run --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .branch)" = "bugfix/login-bug" ]
}

@test "new legt Worktree an, führt Setup aus und meldet Ports" {
  run wt_json new login-bug --type bugfix --ticket PROJ-1234 --json
  [ "$status" -eq 0 ]
  path="$(echo "$output" | jq -r .path)"
  [ -d "$path" ]
  [ -f "$path/setup.marker" ]
  [ "$(echo "$output" | jq -r .setup_ok)" = "true" ]
  [ "$(echo "$output" | jq -r .ports.VITE_PORT)" -gt 5173 ]
  [ "$(echo "$output" | jq -r .workspace_id)" = "w9" ]
  [ "$(echo "$output" | jq -r .agent_pane)" = "w9:p1" ]
  grep -q '^VITE_PORT=' "$path/.env"
}

@test "env.sh macht Ports und Projektnamen sourcebar" {
  run wt_json new login-bug --type bugfix --json
  [ "$status" -eq 0 ]
  path="$(echo "$output" | jq -r .path)"
  [ -f "$path/.wt/env.sh" ]
  grep -q '^export VITE_PORT=' "$path/.wt/env.sh"
  grep -q "^export COMPOSE_PROJECT_NAME=projekt-login-bug$" "$path/.wt/env.sh"
  grep -q "^export WT_MAIN=$WT_REPO$" "$path/.wt/env.sh"
}

@test "cwd verlagert die Setup-Kommandos ins Unterverzeichnis" {
  cat > "$WT_CONFIG_DIR/projekt.json" <<'JSON'
{ "base": "develop", "branch_pattern": "{type}/{slug}", "cwd": "app",
  "setup": ["echo hier > marker"], "tabs": [ {"name":"claude"} ],
  "ports": { "mode": "none", "vars": {} } }
JSON
  mkdir -p "$WT_REPO/app"
  touch "$WT_REPO/app/.keep"
  git -C "$WT_REPO" add -A
  git -C "$WT_REPO" commit -qm app
  git -C "$WT_REPO" branch -f develop main

  run wt_json new mono --type bugfix --json
  [ "$status" -eq 0 ]
  path="$(echo "$output" | jq -r .path)"
  [ -f "$path/app/marker" ]
  [ ! -f "$path/marker" ]
}

@test "das Briefing-Verzeichnis ist worktree-lokal ausgeschlossen" {
  run wt_json new login-bug --type bugfix --json
  path="$(echo "$output" | jq -r .path)"
  excl="$(git -C "$path" rev-parse --git-path info/exclude)"
  grep -q '\.wt/' "$excl"
  [ ! -f "$path/.gitignore" ]
}

@test "fehlgeschlagenes Setup meldet setup_ok=false und Exit 1" {
  cat > "$WT_CONFIG_DIR/projekt.json" <<'JSON'
{ "base": "develop", "setup": ["exit 3"], "tabs": [ {"name":"claude"} ],
  "ports": { "mode": "none", "vars": {} } }
JSON
  run wt new kaputt --type bugfix --json
  [ "$status" -eq 1 ]
  [[ "$output" == *"Setup fehlgeschlagen"* ]]
  [[ "$output" == *"exit 3"* ]]
  # Der Worktree bleibt zum Nachsehen stehen
  [ -d "$WT_WORKTREE_DIR/projekt/kaputt" ]
}

@test "fehlender Basis-Branch bricht ab, bevor etwas angelegt wird" {
  run wt new x --base gibtsnicht --json
  [ "$status" -eq 1 ]
  [[ "$output" == *"Basis-Branch nicht gefunden"* ]]
  [ ! -d "$WT_WORKTREE_DIR/projekt/x" ]
}

@test "ohne herdr-Server entsteht der Worktree trotzdem" {
  cat > "$WT_HERDR_BIN" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
  chmod +x "$WT_HERDR_BIN"
  run wt_json new login-bug --type bugfix --json
  [ "$status" -eq 0 ]
  [ -d "$(echo "$output" | jq -r .path)" ]
  [ "$(echo "$output" | jq -r .workspace_id)" = "null" ]
}

@test "ohne herdr-Server wird der eingeschränkte Modus gemeldet" {
  cat > "$WT_HERDR_BIN" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
  chmod +x "$WT_HERDR_BIN"
  run wt new login-bug --type bugfix --json
  [ "$status" -eq 0 ]
  [[ "$output" == *"ohne herdr"* ]]
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/new.bats`
Expected: FAIL — `noch nicht implementiert: new`

- [ ] **Step 3: `cmd_new` implementieren**

In `bin/wt` alle Bibliotheken sourcen:

```zsh
source "$WT_LIB/util.zsh"
source "$WT_LIB/config.zsh"
source "$WT_LIB/state.zsh"
source "$WT_LIB/ports.zsh"
source "$WT_LIB/envfile.zsh"
source "$WT_LIB/git.zsh"
source "$WT_LIB/herdr.zsh"
```

Branch-Namen bauen — leere Platzhalter dürfen keinen doppelten Trenner hinterlassen:

```zsh
wt_branch_name() {
  local pattern=$1 type=$2 ticket=$3 slug=$4
  local out=$pattern
  out=${out//\{type\}/$type}
  out=${out//\{ticket\}/$ticket}
  out=${out//\{slug\}/$slug}
  # Leeres {ticket} hinterlässt "bugfix/-login-bug"
  out=${out//--/-}
  out=${out//\/-/\/}
  out=${out%-}
  printf '%s\n' "$out"
}

# Arbeitsverzeichnis für Setup-, Teardown- und Pane-Kommandos.
# Honoriert den optionalen cwd-Schlüssel (Monorepo-Unterverzeichnis).
wt_work_dir() {
  local wt_path=$1 config=$2 sub
  sub=$(printf '%s' "$config" | jq -r '.cwd // empty')
  if [[ -n $sub ]]; then
    printf '%s\n' "$wt_path/$sub"
  else
    printf '%s\n' "$wt_path"
  fi
}

# Schreibt die Umgebung des Worktrees als sourcebare Datei.
# Nötig, weil "herdr worktree create" kein --env kennt: der Agent-Tab bekommt
# die Ports also nicht über herdr, sondern liest sie hier.
wt_env_script_write() {
  local wt_path=$1 ports=$2 label=$3 repo=$4
  mkdir -p "$wt_path/.wt"
  {
    print -- "# Von wt erzeugt. In der Shell: source .wt/env.sh"
    printf '%s' "$ports" | jq -r '.ports | to_entries[] | "export \(.key)=\(.value)"'
    print -- "export COMPOSE_PROJECT_NAME=$label"
    print -- "export WT_MAIN=$repo"
  } > "$wt_path/.wt/env.sh"
}

# Führt die Setup-Kommandos im Worktree aus. Erstes Scheitern beendet.
wt_run_steps() {
  local dir=$1 label=$2
  shift 2
  local cmd
  for cmd in "$@"; do
    [[ -n $cmd ]] || continue
    # stderr: stdout gehört bei --json allein dem JSON
    print -u2 -- "wt: $label: $cmd"
    ( cd "$dir" && eval "$cmd" ) || {
      print -u2 -- "wt: $label fehlgeschlagen: $cmd"
      return 1
    }
  done
  return 0
}

cmd_new() {
  local slug='' base='' type=bugfix ticket='' dry=0 want_json=0
  while (( $# )); do
    case $1 in
      --base)    base=$2; shift 2 ;;
      --type)    type=$2; shift 2 ;;
      --ticket)  ticket=$2; shift 2 ;;
      --dry-run) dry=1; shift ;;
      --json)    want_json=1; shift ;;
      -*)        wt_usage_die "unbekannte Option: $1" ;;
      *)         slug=$1; shift ;;
    esac
  done
  [[ -n $slug ]] || wt_usage_die "wt new <slug> [--base <ref>] [--type bugfix|feature] [--ticket <id>]"

  local config repo pattern
  config=$(wt_config_load) || return 1
  repo=$(printf '%s' "$config" | jq -r .repo)
  [[ -n $base ]] || base=$(printf '%s' "$config" | jq -r .base)
  pattern=$(printf '%s' "$config" | jq -r .branch_pattern)

  local branch path label ports
  branch=$(wt_branch_name "$pattern" "$type" "$ticket" "$slug")
  wt_path=$(wt_worktree_path "$repo" "$slug")
  label="${repo:t}-$slug"
  ports=$(wt_ports_alloc "$slug" "$config") || return 1

  if (( dry )); then
    jq -c -n --arg s "$slug" --arg b "$branch" --arg p "$wt_path" \
      --arg base "$base" --arg label "$label" \
      --argjson ports "$(printf '%s' "$ports" | jq .ports)" \
      --argjson setup "$(printf '%s' "$config" | jq .setup)" \
      '{dry_run:true, slug:$s, branch:$b, path:$p, base:$base,
        compose_project:$label, ports:$ports, setup:$setup}'
    return 0
  fi

  wt_base_update "$repo" "$base" || return 1
  wt_path=$(wt_worktree_create "$repo" "$slug" "$branch" "$base") || return 1

  wt_git_exclude "$wt_path" '.wt/'
  wt_git_exclude "$wt_path" 'docker-compose.override.yml'
  mkdir -p "$wt_path/.wt"

  wt_env_write "$wt_path" "$ports"
  wt_compose_override_write "$wt_path" "$config" "$ports"

  local -a setup_steps
  setup_steps=(${(f)"$(printf '%s' "$config" | jq -r '.setup[]?')"})

  local -a envexport
  local k v
  while IFS='=' read -r k v; do
    [[ -n $k ]] && export "$k=$v"
  done < <(printf '%s' "$ports" | jq -r '.ports | to_entries[] | "\(.key)=\(.value)"')
  export COMPOSE_PROJECT_NAME="$label"
  export WT_MAIN="$repo"

  wt_env_script_write "$wt_path" "$ports" "$label" "$repo"

  local workdir setup_ok=true
  workdir=$(wt_work_dir "$wt_path" "$config")
  if (( ${#setup_steps} )); then
    wt_run_steps "$workdir" "Setup" "${setup_steps[@]}" || setup_ok=false
  fi

  local ws='null' agent='null'
  if [[ $setup_ok == true ]]; then
    if wt_herdr_available; then
      local built
      # path für den Worktree selbst, workdir als cwd der Tabs und Panes
      built=$(wt_herdr_build "$wt_path" "$workdir" "$label" "$branch" "$base" "$config" "$ports") \
        && {
          ws=$(printf '%s' "$built" | jq .workspace_id)
          agent=$(printf '%s' "$built" | jq .agent_pane)
        }
    else
      wt_warn "ohne herdr: nur der Worktree wurde angelegt ($wt_path)"
    fi
  fi

  wt_state_merge "$slug" "$(jq -c -n \
    --arg b "$branch" --arg p "$wt_path" --arg base "$base" --arg label "$label" \
    --argjson ws "$ws" \
    '{branch:$b, path:$p, base:$base, compose_project:$label, workspace_id:$ws}')"

  local result
  result=$(jq -c -n --arg s "$slug" --arg b "$branch" --arg p "$wt_path" \
    --arg base "$base" --arg label "$label" \
    --argjson ports "$(printf '%s' "$ports" | jq .ports)" \
    --argjson ws "$ws" --argjson agent "$agent" \
    --argjson ok "$setup_ok" \
    '{slug:$s, branch:$b, path:$p, base:$base, compose_project:$label,
      ports:$ports, workspace_id:$ws, agent_pane:$agent, setup_ok:$ok}')

  if (( want_json )); then
    printf '%s\n' "$result"
  else
    printf '%s\n' "$result" | jq .
  fi

  [[ $setup_ok == true ]] || wt_die "Setup fehlgeschlagen — kein Agent gestartet, Worktree bleibt unter $wt_path"
  return 0
}
```

Im `case` von `main` ergänzen:

```zsh
    new) shift; cmd_new "$@" ;;
```

- [ ] **Step 4: Tests laufen lassen**

Run: `bats tests/new.bats`
Expected: 10 Tests PASS

- [ ] **Step 5: Gesamtsuite und Syntax prüfen**

```bash
zsh -n bin/wt
bats tests/
```

Expected: alle Tests PASS

- [ ] **Step 6: Commit**

```bash
git add bin/wt tests/new.bats
git commit -m "feat: wire up wt new with a dry-run mode"
```

---

### Task 8: `wt ls`, `up`, `down`, `rm`, `prune`

**Files:**
- Modify: `bin/wt`
- Create: `tests/lifecycle.bats`

**Interfaces:**
- Consumes: alles aus Task 2–7
- Produces: `cmd_ls`, `cmd_up`, `cmd_down`, `cmd_rm`, `cmd_prune`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`tests/lifecycle.bats`:

```bash
#!/usr/bin/env bats

load helper

setup() {
  wt_tmpdirs
  wt_fixture_repo
  wt_stub_herdr
  cd "$WT_REPO"
  cat > "$WT_CONFIG_DIR/projekt.json" <<'JSON'
{
  "base": "develop",
  "branch_pattern": "{type}/{slug}",
  "setup": [],
  "teardown": ["echo teardown-lief > $WT_MAIN/teardown.marker"],
  "tabs": [ {"name":"claude"} ],
  "ports": { "mode": "env", "vars": { "VITE_PORT": 5173 } }
}
JSON
  wt new eins --type bugfix --json > /dev/null
}
teardown() { wt_cleanup; }

@test "ls listet den Worktree mit Branch und Ports" {
  run wt ls --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.[0].slug')" = "eins" ]
  [ "$(echo "$output" | jq -r '.[0].branch')" = "bugfix/eins" ]
  [ "$(echo "$output" | jq -r '.[0].ports.VITE_PORT')" -gt 5173 ]
}

@test "rm führt Teardown aus, entfernt Worktree und Zustand" {
  path="$WT_WORKTREE_DIR/projekt/eins"
  run wt rm eins
  [ "$status" -eq 0 ]
  [ -f "$WT_REPO/teardown.marker" ]
  [ ! -d "$path" ]
  [ ! -f "$WT_STATE_DIR/projekt/eins.json" ]
  grep -q 'workspace close' "$WT_HERDR_LOG"
}

@test "rm verweigert uncommittete Änderungen ohne --force" {
  path="$WT_WORKTREE_DIR/projekt/eins"
  echo aenderung >> "$path/README.md"
  run wt rm eins
  [ "$status" -eq 1 ]
  [[ "$output" == *"uncommittete Änderungen"* ]]
  [ -d "$path" ]
}

@test "rm --force räumt trotz Änderungen ab" {
  path="$WT_WORKTREE_DIR/projekt/eins"
  echo aenderung >> "$path/README.md"
  run wt rm eins --force
  [ "$status" -eq 0 ]
  [ ! -d "$path" ]
}

@test "unbekannter Slug bei rm endet mit Klartext" {
  run wt rm gibtsnicht
  [ "$status" -eq 1 ]
  [[ "$output" == *"unbekannter Worktree: gibtsnicht"* ]]
}

@test "prune nennt gemergte Worktrees und lässt ungemergte stehen" {
  # eins nach develop mergen
  git -C "$WT_REPO" merge -q --no-ff -m merge bugfix/eins
  wt new zwei --type bugfix --json > /dev/null
  path_zwei="$WT_WORKTREE_DIR/projekt/zwei"
  echo neu > "$path_zwei/neu.txt"
  git -C "$path_zwei" add -A
  git -C "$path_zwei" commit -qm neu

  run wt prune --json
  [ "$status" -eq 0 ]
  [[ "$output" == *eins* ]]
  [[ "$output" != *zwei* ]]
  # --json meldet nur, räumt nicht ab
  [ -d "$WT_WORKTREE_DIR/projekt/eins" ]
}

@test "prune --yes räumt die gemergten wirklich ab" {
  git -C "$WT_REPO" merge -q --no-ff -m merge bugfix/eins
  run wt prune --yes
  [ "$status" -eq 0 ]
  [ ! -d "$WT_WORKTREE_DIR/projekt/eins" ]
}

@test "up und down führen run- bzw. teardown-Kommandos aus" {
  cat > "$WT_CONFIG_DIR/projekt.json" <<'JSON'
{ "base": "develop", "branch_pattern": "{type}/{slug}",
  "setup": ["echo up-lief > up.marker"],
  "teardown": ["echo down-lief > down.marker"],
  "tabs": [ {"name":"claude"} ], "ports": { "mode": "none", "vars": {} } }
JSON
  path="$WT_WORKTREE_DIR/projekt/eins"
  run wt up eins
  [ "$status" -eq 0 ]
  [ -f "$path/up.marker" ]
  run wt down eins
  [ "$status" -eq 0 ]
  [ -f "$path/down.marker" ]
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/lifecycle.bats`
Expected: FAIL — `noch nicht implementiert: ls`

- [ ] **Step 3: Die Lebenszyklus-Kommandos implementieren**

In `bin/wt` einfügen:

```zsh
# Zustand eines Slugs holen oder mit Klartext scheitern.
wt_state_or_die() {
  local slug=$1 state
  state=$(wt_state_read "$slug" 2>/dev/null) \
    || wt_die "unbekannter Worktree: $slug"
  printf '%s\n' "$state"
}

cmd_ls() {
  local want_json=0
  [[ " $* " == *" --json "* ]] && want_json=1

  local out='[]' slug state path branch running
  while read -r slug; do
    [[ -n $slug ]] || continue
    state=$(wt_state_read "$slug") || continue
    wt_path=$(printf '%s' "$state" | jq -r '.path // ""')
    running=false
    [[ -d $wt_path ]] && running=true
    out=$(printf '%s' "$out" | jq -c \
      --arg s "$slug" --argjson st "$state" --argjson ex "$running" \
      '. + [ $st + {slug: $s, exists: $ex} ]')
  done < <(wt_state_list)

  if (( want_json )); then
    printf '%s\n' "$out"
    return 0
  fi

  printf '%s' "$out" | jq -r '.[] |
    "\(.slug)\t\(.branch // "-")\t\(.ports // {} | to_entries | map("\(.key)=\(.value)") | join(" "))"' \
    | column -t -s $'\t'
}

# Führt eine benannte Kommandoliste aus der Konfiguration im Worktree aus.
wt_lifecycle_run() {
  local slug=$1 key=$2 label=$3
  local state path config repo
  state=$(wt_state_or_die "$slug") || return 1
  wt_path=$(printf '%s' "$state" | jq -r .path)
  [[ -d $wt_path ]] || wt_die "Worktree-Verzeichnis fehlt: $wt_path"

  config=$(wt_config_load) || return 1
  repo=$(printf '%s' "$config" | jq -r .repo)

  local k v
  while IFS='=' read -r k v; do
    [[ -n $k ]] && export "$k=$v"
  done < <(printf '%s' "$state" | jq -r '.ports // {} | to_entries[] | "\(.key)=\(.value)"')
  export COMPOSE_PROJECT_NAME="$(printf '%s' "$state" | jq -r '.compose_project // ""')"
  export WT_MAIN="$repo"

  local -a steps
  steps=(${(f)"$(printf '%s' "$config" | jq -r ".${key}[]?")"})
  (( ${#steps} )) || return 0
  wt_run_steps "$(wt_work_dir "$wt_path" "$config")" "$label" "${steps[@]}"
}

cmd_up()   { local slug=${1:-}; [[ -n $slug ]] || wt_usage_die "wt up <slug>";   wt_lifecycle_run "$slug" setup "Start" }
cmd_down() { local slug=${1:-}; [[ -n $slug ]] || wt_usage_die "wt down <slug>"; wt_lifecycle_run "$slug" teardown "Stop" }

cmd_rm() {
  local slug='' force=0
  while (( $# )); do
    case $1 in
      --force) force=1; shift ;;
      -*) wt_usage_die "unbekannte Option: $1" ;;
      *) slug=$1; shift ;;
    esac
  done
  [[ -n $slug ]] || wt_usage_die "wt rm <slug> [--force]"

  local state path ws config repo
  state=$(wt_state_or_die "$slug") || return 1
  wt_path=$(printf '%s' "$state" | jq -r .path)
  ws=$(printf '%s' "$state" | jq -r '.workspace_id // empty')
  config=$(wt_config_load) || return 1
  repo=$(printf '%s' "$config" | jq -r .repo)

  if [[ -d $wt_path ]] && (( ! force )) && wt_worktree_is_dirty "$wt_path"; then
    wt_die "uncommittete Änderungen in $wt_path — mit --force trotzdem entfernen"
  fi

  [[ -d $wt_path ]] && wt_lifecycle_run "$slug" teardown "Teardown" || true

  if [[ -n $ws && $ws != null ]] && wt_herdr_available; then
    # Die ID ist positional, nicht --workspace.
    "$(wt_herdr_bin)" workspace close "$ws" >/dev/null 2>&1 \
      || wt_warn "Workspace $ws konnte nicht geschlossen werden"
  fi

  [[ -d $wt_path ]] && wt_worktree_remove "$repo" "$wt_path"
  wt_state_delete "$slug"
  print -u2 -- "wt: $slug entfernt"
}

cmd_prune() {
  local want_json=0 yes=0
  while (( $# )); do
    case $1 in
      --json) want_json=1; shift ;;
      --yes|-y) yes=1; shift ;;
      *) wt_usage_die "unbekannte Option: $1" ;;
    esac
  done

  local config repo base
  config=$(wt_config_load) || return 1
  repo=$(printf '%s' "$config" | jq -r .repo)
  base=$(printf '%s' "$config" | jq -r .base)

  local -a merged candidates
  merged=(${(f)"$(wt_worktree_merged "$repo" "$base")"})

  local slug state branch
  while read -r slug; do
    [[ -n $slug ]] || continue
    state=$(wt_state_read "$slug") || continue
    branch=$(printf '%s' "$state" | jq -r '.branch // ""')
    if (( ${merged[(Ie)$branch]} )); then
      candidates+=("$slug")
    fi
  done < <(wt_state_list)

  if (( want_json )); then
    printf '%s\n' "${(j:,:)candidates}" | jq -R 'split(",") | map(select(. != ""))'
    return 0
  fi

  if (( ${#candidates} == 0 )); then
    print -u2 -- "wt: nichts abzuräumen"
    return 0
  fi

  print -u2 -- "wt: in $base gemergt: ${candidates[*]}"
  if (( ! yes )); then
    print -n -- "wt: entfernen? [j/N] "
    local answer
    read -r answer
    [[ $answer == (j|J|y|Y) ]] || { print -u2 -- "wt: abgebrochen"; return 0 }
  fi

  local s
  for s in "${candidates[@]}"; do
    cmd_rm "$s" --force
  done
}
```

Im `case` von `main`:

```zsh
    ls)    shift; cmd_ls "$@" ;;
    up)    shift; cmd_up "$@" ;;
    down)  shift; cmd_down "$@" ;;
    rm)    shift; cmd_rm "$@" ;;
    prune) shift; cmd_prune "$@" ;;
```

Hinweis zu `up`: Es benutzt bewusst dieselbe `setup`-Liste. Weil Setup idempotent sein muss (Spec-Vorgabe), ist „hochfahren" und „einrichten" dasselbe Kommando — eine getrennte `run`-Liste wäre eine zweite Wahrheit über denselben Sachverhalt.

- [ ] **Step 4: Tests laufen lassen**

Run: `bats tests/lifecycle.bats`
Expected: 8 Tests PASS

- [ ] **Step 5: Gesamtsuite, Syntax, Commit**

```bash
zsh -n bin/wt
bats tests/
git add bin/wt tests/lifecycle.bats
git commit -m "feat: add ls, up, down, rm and prune"
```

---

### Task 9: `wt doctor`

**Files:**
- Modify: `bin/wt`
- Create: `tests/doctor.bats`

**Interfaces:**
- Consumes: `wt_config_load`, `wt_config_path`, `wt_compose_supports_override`
- Produces: `wt doctor [--json]` → Konfigurationsvorschlag auf stdout; schreibt nur mit `--write` und nur, wenn noch keine Datei existiert

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`tests/doctor.bats`:

```bash
#!/usr/bin/env bats

load helper

setup() {
  wt_tmpdirs
  wt_fixture_repo
  cd "$WT_REPO"
}
teardown() { wt_cleanup; }

@test "npm-Projekt: install-Kommando und Dev-Scripts werden erkannt" {
  cat > package.json <<'JSON'
{ "scripts": { "dev": "vite", "start": "node server.js" } }
JSON
  touch package-lock.json
  run wt doctor --json
  [ "$status" -eq 0 ]
  [[ "$(echo "$output" | jq -r '.setup | join(" ")')" == *"npm ci"* ]]
  [[ "$(echo "$output" | jq -r '.tabs | tostring')" == *"npm run dev"* ]]
}

@test "Lockfile entscheidet über den Paketmanager" {
  echo '{}' > package.json
  rm -f package-lock.json
  touch pnpm-lock.yaml
  run wt doctor --json
  [[ "$(echo "$output" | jq -r '.setup | join(" ")')" == *"pnpm install"* ]]
}

@test "Compose-Datei ergibt einen up-Schritt und einen teardown" {
  printf 'services:\n  db:\n    image: postgres\n' > docker-compose.yml
  run wt doctor --json
  [[ "$(echo "$output" | jq -r '.setup | join(" ")')" == *"docker compose up -d"* ]]
  [[ "$(echo "$output" | jq -r '.teardown | join(" ")')" == *"docker compose down -v"* ]]
}

@test "eigenes make-Ziel hat Vorrang vor nachgebauten Schritten" {
  printf 'bootstrap:\n\t@echo hi\n' > Makefile
  echo '{}' > package.json
  run wt doctor --json
  [ "$(echo "$output" | jq -r '.setup | length')" = "1" ]
  [ "$(echo "$output" | jq -r '.setup[0]')" = "make bootstrap" ]
}

@test "feste Ports in der Compose-Datei ergeben mode=override" {
  printf 'services:\n  client:\n    ports:\n      - "5173:5173"\n' > docker-compose.yml
  run wt doctor --json
  [ "$(echo "$output" | jq -r .ports.mode)" = "override" ]
  [ "$(echo "$output" | jq -r '.ports.services.client[0].host')" = "5173" ]
}

@test "variable Ports ergeben mode=env" {
  printf 'services:\n  client:\n    ports:\n      - "${VITE_PORT}:5173"\n' > docker-compose.yml
  run wt doctor --json
  [ "$(echo "$output" | jq -r .ports.mode)" = "env" ]
  [ "$(echo "$output" | jq -r .ports.vars.VITE_PORT)" = "5173" ]
}

@test "--write legt die Datei an, überschreibt aber nie" {
  echo '{}' > package.json
  run wt doctor --write
  [ "$status" -eq 0 ]
  [ -f "$WT_CONFIG_DIR/projekt.json" ]
  run wt doctor --write
  [ "$status" -eq 1 ]
  [[ "$output" == *"existiert bereits"* ]]
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `bats tests/doctor.bats`
Expected: FAIL — `noch nicht implementiert: doctor`

- [ ] **Step 3: `cmd_doctor` implementieren**

```zsh
wt_doctor_pkg_install() {
  [[ -f pnpm-lock.yaml ]]     && { print -- "pnpm install --frozen-lockfile"; return }
  [[ -f yarn.lock ]]          && { print -- "yarn install --frozen-lockfile"; return }
  [[ -f bun.lockb ]]          && { print -- "bun install"; return }
  [[ -f package-lock.json ]]  && { print -- "npm ci"; return }
  [[ -f package.json ]]       && { print -- "npm install"; return }
  return 1
}

wt_doctor_compose_file() {
  local f
  for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
    [[ -f $f ]] && { print -- "$f"; return 0 }
  done
  return 1
}

# Liest Port-Zeilen aus einer Compose-Datei und entscheidet den Modus.
# Ausgabe: JSON-Objekt für den ports-Schlüssel der Konfiguration.
wt_doctor_ports() {
  local file=$1
  [[ -n $file && -f $file ]] || { print -- '{"mode":"none","vars":{}}'; return }

  # Variable Bindings: "${VAR}:1234" oder "$VAR:1234"
  local vars
  vars=$(grep -o -E '"\$\{?[A-Z_][A-Z0-9_]*\}?:[0-9]+"' "$file" 2>/dev/null \
    | sed -E 's/"\$\{?([A-Z_][A-Z0-9_]*)\}?:([0-9]+)"/\1 \2/' || true)

  if [[ -n $vars ]]; then
    print -- "$vars" | jq -R -s '
      {mode: "env",
       vars: ( split("\n") | map(select(length > 0) | split(" "))
               | map({key: .[0], value: (.[1] | tonumber)}) | from_entries )}'
    return
  fi

  # Feste Bindings: "1234:5678", jeweils dem vorangehenden Service zugeordnet
  local fixed
  fixed=$(awk '
    /^[[:space:]]{2}[a-zA-Z0-9_-]+:[[:space:]]*$/ {
      svc = $1; sub(/:$/, "", svc); next
    }
    /- *"?[0-9]+:[0-9]+"?/ {
      line = $0
      gsub(/[^0-9:]/, " ", line)
      split(line, a, " ")
      for (i in a) if (a[i] ~ /^[0-9]+:[0-9]+$/) {
        split(a[i], p, ":")
        print svc, p[1], p[2]
      }
    }
  ' "$file")

  if [[ -n $fixed ]]; then
    print -- "$fixed" | jq -R -s '
      {mode: "override",
       services: ( split("\n") | map(select(length > 0) | split(" "))
                   | group_by(.[0])
                   | map({key: .[0][0],
                          value: map({host: (.[1]|tonumber),
                                      container: (.[2]|tonumber)})})
                   | from_entries )}'
    return
  fi

  print -- '{"mode":"none","vars":{}}'
}

cmd_doctor() {
  local want_json=0 write=0
  while (( $# )); do
    case $1 in
      --json)  want_json=1; shift ;;
      --write) write=1; shift ;;
      *) wt_usage_die "unbekannte Option: $1" ;;
    esac
  done

  local repo path
  repo=$(wt_repo_root) || return 1
  wt_path=$(wt_config_path) || return 1

  local -a setup teardown
  local -a tabs_json
  local compose ports install

  cd "$repo"
  compose=$(wt_doctor_compose_file) || compose=''

  # Ein eigenes Bootstrap-Ziel hat Vorrang: nicht nachbauen, delegieren.
  if [[ -f Makefile ]] && grep -q -E '^bootstrap:' Makefile; then
    setup=("make bootstrap")
  else
    install=$(wt_doctor_pkg_install) && setup+=("$install")
    [[ -n $compose ]] && setup+=("docker compose up -d")
  fi
  [[ -n $compose ]] && teardown+=("docker compose down -v")

  local -a panes
  if [[ -f package.json ]]; then
    local s
    for s in dev serve start; do
      jq -e --arg s "$s" '.scripts[$s] // empty' package.json >/dev/null 2>&1 \
        && panes+=("$s")
    done
  fi

  ports=$(wt_doctor_ports "$compose")

  local tabs
  tabs=$(jq -c -n --argjson panes "$(printf '%s\n' "${panes[@]}" \
      | jq -R -s 'split("\n") | map(select(length > 0))')" '
    [ {name: "claude"}, {name: "edit", command: "nvim"} ]
    + ( if ($panes | length) > 0
        then [ {name: "stack",
                panes: ( $panes | to_entries | map({
                  name: .value,
                  command: ("npm run " + .value),
                  direction: (if .key == 0 then null else "right" end)
                } | with_entries(select(.value != null)) )) } ]
        else [] end )')

  local suggestion
  suggestion=$(jq -c -n \
    --arg repo "$repo" \
    --argjson setup "$(printf '%s\n' "${setup[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')" \
    --argjson teardown "$(printf '%s\n' "${teardown[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')" \
    --argjson tabs "$tabs" --argjson ports "$ports" \
    '{repo: $repo, base: "develop", branch_pattern: "{type}/{ticket}-{slug}",
      cwd: null, setup: $setup, teardown: $teardown, tabs: $tabs, ports: $ports}')

  if [[ $(printf '%s' "$ports" | jq -r .mode) == override ]] \
     && ! wt_compose_supports_override; then
    wt_warn "Docker Compose < 2.24 — das !override-Tag wirkt nicht, Ports kollidieren weiter"
  fi

  if (( write )); then
    [[ -f $wt_path ]] && wt_die "$wt_path existiert bereits — nicht überschrieben"
    mkdir -p "${wt_path:h}"
    printf '%s\n' "$suggestion" | jq . > "$wt_path"
    print -u2 -- "wt: geschrieben nach $wt_path"
    return 0
  fi

  if (( want_json )); then
    printf '%s\n' "$suggestion"
  else
    printf '%s\n' "$suggestion" | jq .
    print -- ""
    print -- "Mit 'wt doctor --write' nach $wt_path schreiben."
  fi
}
```

Im `case` von `main`:

```zsh
    doctor) shift; cmd_doctor "$@" ;;
```

Die Zeile `new|ls|up|down|rm|prune|ports|config|doctor) wt_die "noch nicht implementiert…"` entfällt jetzt vollständig.

- [ ] **Step 4: Tests laufen lassen**

Run: `bats tests/doctor.bats`
Expected: 7 Tests PASS

- [ ] **Step 5: Gesamtsuite und Syntax prüfen**

```bash
zsh -n bin/wt
for f in lib/*.zsh; do zsh -n "$f" || echo "SYNTAX: $f"; done
bats tests/
```

Expected: alle Tests PASS, keine Syntaxmeldung

- [ ] **Step 6: Commit**

```bash
git add bin/wt tests/doctor.bats
git commit -m "feat: add doctor to bootstrap a project configuration"
```

---

### Task 10: Verlinken und gegen ein echtes Repo verifizieren

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: alles
- Produces: nichts (Verifikationsaufgabe)

- [ ] **Step 1: `wt` in den PATH bringen**

Nur die eine Datei wird verlinkt; die Bibliothek findet sich über `${0:A}` von selbst:

```bash
mkdir -p ~/.local/bin
ln -sfn ~/development/wt/bin/wt ~/.local/bin/wt
hash -r
wt --version
```

Expected: `wt 0.1.0`

- [ ] **Step 2: Prüfen, dass die Bibliothek über den Symlink gefunden wird**

```bash
env -u WT_LIB wt help
```

Expected: die Hilfe erscheint — belegt, dass `${0:A:h:h}/lib` durch den Symlink hindurch auflöst. Ohne diesen Schritt fällt ein kaputter Pfad erst im Alltag auf, weil die Tests `WT_LIB` explizit setzen.

- [ ] **Step 3: Gegen die Dotfiles selbst durchspielen**

Ein Trockenlauf in einem echten Repo ohne Konfiguration:

```bash
cd ~/dotfiles
wt new probe --type feature --dry-run --json | jq .
```

Expected: JSON mit `branch: "feature/probe"`, `dry_run: true`, leerem `setup`; kein Verzeichnis unter `~/.herdr/worktrees` angelegt.

- [ ] **Step 4: Einen echten Worktree anlegen und wieder abräumen**

```bash
cd ~/dotfiles
wt new probe --type feature --json | jq .
wt ls
herdr workspace list | jq '.result.workspaces[] | {workspace_id, label}'
wt rm probe
wt ls
```

Expected: Workspace erscheint in der Sidebar mit dem Label `dotfiles-probe`, `wt ls` listet ihn, nach `wt rm` ist er in beiden Ausgaben verschwunden.

- [ ] **Step 5: `README.md` anlegen**

Das Repo hat noch keine. Diesen Inhalt als `README.md` schreiben:

````markdown
# wt — Worktree-Arbeitsplätze

`wt` macht aus einem Slug einen arbeitsfähigen, isolierten Git-Worktree: eigener
Branch von der Basis, eigene Ports, eigener Docker-Stack, eigener herdr-Workspace
mit dem konfigurierten Tab-Layout. Mehrere Tickets laufen dadurch gleichzeitig,
ohne sich Ports, Container oder Migrationsstände zu teilen.

| Kommando | Wirkung |
|---|---|
| `wt new <slug> [--base <ref>] [--type bugfix\|feature] [--ticket <id>]` | Worktree anlegen und einrichten; `--dry-run` zeigt nur, was passieren würde |
| `wt ls` | Worktrees mit Branch und Ports |
| `wt up <slug>` / `wt down <slug>` | Dienste starten / stoppen |
| `wt rm <slug> [--force]` | Teardown, Worktree und Workspace entfernen |
| `wt prune [--yes]` | In die Basis gemergte Worktrees abräumen |
| `wt ports <slug>` | Zugeteilte Ports und URLs |
| `wt doctor [--write]` | Repo untersuchen und eine Projekt-Konfiguration vorschlagen |

## Installation

```bash
git clone <remote> ~/development/wt
ln -sfn ~/development/wt/bin/wt ~/.local/bin/wt
brew install jq            # zwingend
brew install bats-core     # nur für die Tests
```

`wt` braucht sonst nichts: zsh und `nc` liefert macOS mit, `herdr` ist optional
(ohne läuft es im eingeschränkten Modus und legt nur den Worktree an).

## Konfiguration

Pro Repo eine Datei in `~/.config/wt/<repo-name>.json` — bewusst außerhalb
des Projekts, damit in fremden Repositories keine Dateien entstehen. Diese Dateien
liegen versioniert in den Dotfiles unter `.config/wt/`. Einstieg in ein neues
Projekt:

```bash
cd ~/pfad/zum/projekt
wt doctor          # Vorschlag ansehen
wt doctor --write  # übernehmen
wt new mein-ticket --type bugfix
```

Ports werden deterministisch aus dem Slug abgeleitet, derselbe Worktree behält
also seine URLs. Container werden über `COMPOSE_PROJECT_NAME` getrennt, jeder
Worktree hat damit eigene Volumes und einen eigenen Migrationsstand.

Entwurf und Begründung der Entscheidungen liegen im Dotfiles-Repo:
`~/dotfiles/docs/superpowers/specs/2026-08-05-worktree-ticket-workflow-design.md`
````

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: document the wt command"
```

---

## Was dieser Plan nicht abdeckt

Plan B, nach Abschluss von Plan A und einer Verifikation gegen das echte Arbeitsprojekt:

- `/wt-setup` — Konfiguration aus dem Repo erschließen und gegen einen Wegwerf-Worktree verifizieren (`wt doctor` liefert dafür die Rohdaten)
- `bugfix-workflow` und `feature-workflow` als Worker-Playbooks
- `/ticket` und `/tickets` als Hub-Skills
- Die Browser-Sperrdatei `~/.local/state/wt/browser.lock` — sie gehört zum Playbook, nicht zum Bootstrap-Kommando
- Das Sicherheitsnetz „vor jedem Commit prüfen, dass der Branch nicht der Basis-Branch ist" — es gehört in die Playbooks, weil `wt` nie committet
- Das Schreiben von `.wt/BRIEFING.md`, `PLAN.md`, `JOURNAL.md` und `TICKET.md`; `wt new` legt nur das Verzeichnis an und schließt es aus

Ebenfalls offen und in der Spec als solches vermerkt: das Aufräumen der Superset-Notify-Hooks in `settings.json`.

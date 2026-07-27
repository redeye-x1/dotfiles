# SketchyBar-Migration — Design

Datum: 2026-07-27
Status: freigegeben

## Motivation

Die Statusbar läuft heute als simple-bar unter Übersicht, also als WebKit-View.
Jedes Datenwidget ist eine React-Komponente, die in einem Intervall einen
Shell-Command startet und danach neu rendert. Der Wechsel auf SketchyBar
(natives C, v2.24.0 vom 2026-06-04) soll diese Last loswerden.

Performance ist das einzige Motiv. Optik und Funktionsumfang sollen bleiben,
wie sie heute sind.

Ausdrücklich **kein** Motiv: das `<redacted>` beim WLAN-Namen. Das ist eine
TCC-Sperre von macOS 14+ und trifft SketchyBar genauso (siehe Commit `ed5fb36`).
Sie liess sich nachträglich lösen, aber unabhängig von der Migration — siehe den
Abschnitt zum WLAN-Namen weiter unten.

## Ausgangslage

Aktive Widgets laut `.simplebarrc`:

- links: Aerospace-Workspaces mit App-Icons
- Mitte: leer (`processWidget: false`)
- rechts, in Renderreihenfolge aus `index.jsx:262-273`:
  Netstats (als Graph) · CPU · Memory · Battery · Sound · WiFi · Date · Time

Eine ältere SketchyBar-Config liegt in der History unter `2767735^`. Sie wird
**nicht** als Basis verwendet — sie pollte jede Sekunde per `io.popen` und rief
alle zwei Sekunden `top -l 2` auf, was für sich genommen rund eine Sekunde
blockiert. Genau das ist das Problem, das die Migration lösen soll.

## Architektur

SbarLua für die Logik plus kompilierte C-Event-Provider für CPU und Netzwerk —
die Architektur aus Felix Kratz' eigener Config (`FelixKratz/dotfiles`,
`.config/sketchybar/helpers/event_providers/`).

Ein persistenter Lua-Prozess hält den Zustand und reagiert auf Events. Die
C-Provider laufen als eigene Prozesse und pushen `cpu_update` bzw.
`network_update` in die Bar, statt dass die Bar pollt.

### Datenfluss

| Item | Quelle | Prozesse im Betrieb |
|---|---|---|
| CPU | C-Provider `cpu_load` → `cpu_update` | 1 persistent |
| Netstats | C-Provider `network_load en0` → `network_update` | 1 persistent |
| Sound | natives Event `volume_change` | 0 |
| WiFi | natives Event `wifi_change` | 0 |
| Battery | natives Event `power_source_change` + 10s-Tick | nahe 0 |
| Date/Time | `os.date()` im Lua-Prozess | 0 |
| Memory | `vm_stat` alle 4s | 1 Shell / 4s |
| Workspaces | `exec-on-workspace-change`, `on-window-detected`, `on-focus-changed`, `front_app_switched` | nur bei Bedarf |

Fünf der neun Items werden gepusht statt gepollt.

### Dateistruktur

```
.config/sketchybar/
  sketchybarrc
  init.lua
  bar.lua
  default.lua
  colors.lua
  settings.lua
  helpers/
    init.lua
    default_font.lua
    app_icons.lua
    makefile
    event_providers/
      makefile
      sketchybar.h
      cpu_load/
      network_load/
  items/
    init.lua
    workspaces.lua
    widgets/
      init.lua
      netstats.lua
      cpu.lua
      memory.lua
      battery.lua
      sound.lua
      wifi.lua
      datetime.lua
```

Jede Widget-Datei registriert genau ein Item und dessen Event-Abos. Sie kennt
`colors.lua` und `settings.lua`, sonst nichts. Kein Widget greift auf ein
anderes zu.

## Optik

Alle Werte stammen aus `.simplebarrc`, nicht aus der alten Config.

**Bar** — Höhe 39, Hintergrund `0xff2e3440`, Padding links und rechts 10,
Position oben, kein Blur. Die 39 und die 10 kommen aus dem
`customStyles`-Block.

**Schrift** — SF Pro 11px für Text, SF Symbols für Icons, entsprechend
`"font": "SF Pro"` und `"fontSize": "11px"`. Die alte Config verwendete
JetBrainsMono Nerd Font; das steht nicht im Brewfile und wäre auf einer frischen
Maschine kaputt gewesen. SF Pro ist über `cask "font-sf-pro"` abgedeckt.

**Farben** — `colors.lua` wird aus dem `themes`-Block generiert:

| Rolle | Hex | SketchyBar |
|---|---|---|
| Bar-Hintergrund | `#2e3440` | `0xff2e3440` |
| Widget-Hintergrund | `#3b4252` | `0xff3b4252` |
| Inaktiv | `#4c566a` | `0xff4c566a` |
| Akzent, fokussierter Workspace | `#88c0d0` | `0xff88c0d0` |
| Vordergrund | `#eceff4` | `0xffeceff4` |

**Datenwidgets monochrom** in `#eceff4`, entsprechend `"noColorInData": true`.
Die alte Config färbte den CPU-Wert nach Schwellwert ein — das wäre ein
sichtbarer Unterschied zu heute und entfällt.

**Widget-Pillen** — Hintergrund einheitlich `#4c566a`, Padding 9 horizontal,
Höhe 24, abgeleitet aus `.data-widget { padding: 3px 9px; max-height: 30px }`.

simple-bar gibt einzelnen Widgets eigene Hintergrundfarben — Battery Magenta,
Sound Blau, WiFi Rot, Uhrzeit Gelb. Das ist bewusst **nicht** übernommen: alle
Widgets sollen aussehen wie CPU und Memory. Das ist der einzige Punkt, an dem
die Bar absichtlich von simple-bar abweicht.

**Workspaces** — Höhe 25 aus `.spaces { height: 25px }`, dieselbe `#4c566a`-Pille
wie die Datenwidgets, unabhängig davon, ob Fenster darin liegen. Der fokussierte
Workspace hebt sich über den Akzent-Hintergrund mit dunkler Schrift ab; das ist
die einzige verbleibende Farbe in der Bar. App-Icons über
`helpers/app_icons.lua` und `sketchybar-app-font` in Größe 12.

## Nicht im Umfang

- **`dayProgress`.** Der Tagesfortschritt an der Uhr entfällt. Nachrüstbar,
  falls er vermisst wird.
- **Prozess- und Keyboard-Widget.** Sind in `.simplebarrc` bereits aus.
- **Einstellungs-GUI.** SketchyBar hat keine; Konfiguration läuft über Lua.
- **Entfernen von Übersicht und `.simplebarrc`.** Bleiben vorerst als Rückweg
  stehen und werden erst nach erfolgreicher Verifikation in einem separaten
  Commit abgeräumt.

## Änderungen außerhalb der SketchyBar-Config

**`.aerospace.toml`**

```toml
exec-on-workspace-change = [
  '/bin/bash', '-c',
  'sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE'
]
outer.top = [{ monitor."built-in" = 10 }, 49]
```

Die Monitor-Fallunterscheidung muss zurück: SketchyBar zeichnet eine eigene Bar
und braucht auf externen Monitoren 49px Reserve (39 Höhe plus 10 Abstand),
während der eingebaute Monitor die Menüleistenzeile ohnehin freihält.

**`Brewfile`** — `brew "sketchybar"` und `cask "font-sketchybar-app-font"`
ergänzen. `cask "ubersicht"` bleibt vorerst.

**`install.sh`** — SbarLua aus dem Quellcode bauen, `make` in
`helpers/event_providers/`, `brew services start sketchybar`. Der
simple-bar-Klon-Schritt entfällt.

## Verifikation

1. CPU-Last messen, nicht behaupten: Verbrauch von `Übersicht` vor der
   Umstellung gegen `sketchybar` plus die beiden Provider danach.
2. Screenshot-Abgleich gegen die heutige Bar, Widget für Widget.
3. Workspace-Wechsel, App-Start und Fenster-Verschieben durchspielen und
   prüfen, ob die Icons nachziehen.

## Risiken

**Aerospace liefert keine Fenster-Events — erledigt.** Der Entwurf ging von
einem 5-Sekunden-Poll als Fallback aus. Aerospace 0.20 hat aber einen
`on-window-detected`-Callback, und Fenster wandern bei dieser Konfiguration
ausschließlich über die `move-node-to-workspace`-Bindings zwischen Workspaces,
an die sich der Trigger direkt anhängen lässt. Fürs Schließen gibt es keinen
Callback, aber der Fokus verlässt das geschlossene Fenster und löst
`on-focus-changed` aus.

Gemessen: App starten und App beenden schlagen beide nach **1 Sekunde** in der
Bar auf. Der verbleibende Poll steht auf 30 Sekunden und ist reiner Backstop.

**Zwei Compile-Schritte im Setup.** SbarLua und die C-Provider müssen auf jeder
Maschine gebaut werden. Schlägt das fehl, startet die Bar nicht. `install.sh`
muss den Fehler sichtbar machen statt ihn zu verschlucken.

## Korrekturen aus der Umsetzung

Drei Annahmen dieses Entwurfs haben beim Bauen nicht gehalten.

**Die Widgets haben keine einheitliche Pille.** Oben stand, alle Widgets bekämen
`#3b4252` als Hintergrund. Tatsächlich färbt `noColorInData` in simple-bar nur
den *Text* weiß, während jedes Widget seine eigene Hintergrundfarbe behält:
Netstats, CPU, Memory und Datum auf `--minor` (`#4c566a`), Battery auf Magenta,
Sound auf Blau, WiFi auf Rot, Uhrzeit auf Gelb. Die Widgets setzen ihre Farbe
deshalb einzeln, `default.lua` liefert nur `--minor` als Vorgabe.

**`outer.top` musste nicht zurückgebaut werden.** Die Monitor-Fallunterscheidung
`[{ monitor.'built-in' = 10 }, 49]` stand längst wieder in `.aerospace.toml`.

**Lua muss zu SbarLua passen.** SbalLua vendored Lua 5.5 und baut sein Modul
dagegen. Auf dieser Maschine lag noch Lua 5.4.8 — das Modul dort zu laden endet
in SIGSEGV, ohne Fehlermeldung und mit leerer Bar. Die Lösung ist schlicht
`brew upgrade lua`: die aktuelle Formula *ist* 5.5.0, und nichts anderes hängt
an ihr (`brew uses --installed lua` ist leer, Neovim nutzt `luajit`).
`sketchybarrc` bleibt damit beim Upstream-Aufbau mit `#!/usr/bin/env lua`.

Die Kopplung bleibt aber bestehen: sobald Homebrew auf 5.6 geht, bevor SbarLua
nachzieht, kehrt derselbe stille Absturz zurück. `install.sh` vergleicht deshalb
`LUA_DIR` aus SbarLuas Makefile gegen `lua -v` und bricht bei Abweichung mit
einer Meldung ab, statt eine leere Bar zu hinterlassen.

Nebenwirkung des Upgrades: Lua 5.5 macht Schleifenvariablen `const`, was Code
aus 5.4-Beispielen brechen lässt.

Dazu ein Fund, der nichts mit SketchyBar zu tun hat: Homebrew verlangt
inzwischen `brew trust` für Fremd-Taps. Ohne das scheiterte `install.sh` bereits
an `borders`, unabhängig von dieser Migration.

## Rückweg

Die gesamte Migration geht in einen Commit, sodass ein `git revert` zurück auf
simple-bar führt. Übersicht und `.simplebarrc` bleiben währenddessen
installiert.

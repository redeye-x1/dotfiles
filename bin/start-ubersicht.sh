#!/bin/zsh
# Start Übersicht and refresh widgets with retry so simple-bar reliably appears
# at login. Called from AeroSpace's after-startup-command.
open -b tracesOf.Uebersicht
for i in 1 2 3 4 5 6 7 8; do
  sleep 2
  /usr/bin/osascript -e 'tell application id "tracesOf.Uebersicht" to refresh' && break
done

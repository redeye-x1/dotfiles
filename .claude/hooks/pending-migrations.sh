#!/bin/sh
# Lists dotfiles migrations (docs/migrations/NNNN-*.md) not yet applied on this Mac.
#   pending-migrations.sh            print pending names, if any
#   pending-migrations.sh --claude   SessionStart hook output for Claude Code
#   pending-migrations.sh done NAME  record NAME as applied
dir="$HOME/dotfiles/docs/migrations"
state="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/applied-migrations"

if [ "$1" = done ]; then
  [ -f "$dir/$2.md" ] || { echo "No migration named $2" >&2; exit 1; }
  mkdir -p "$(dirname "$state")"
  grep -qx "$2" "$state" 2>/dev/null || echo "$2" >> "$state"
  exit 0
fi

pending=""
for f in "$dir"/[0-9]*.md; do
  [ -e "$f" ] || continue
  name=$(basename "$f" .md)
  case "$name" in *[!0-9a-z-]*) continue ;; esac  # keeps the JSON below valid
  grep -qx "$name" "$state" 2>/dev/null || pending="$pending $name"
done
[ -n "$pending" ] || exit 0

if [ "$1" = --claude ]; then
  printf '{"systemMessage":"Pending dotfiles migrations:%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Pending dotfiles migrations on this Mac:%s. Before other work, read each file in ~/dotfiles/docs/migrations/, show Mago the steps and ask before running them. After a migration is done, run: ~/dotfiles/.claude/hooks/pending-migrations.sh done NAME"}}\n' "$pending" "$pending"
else
  echo "Pending dotfiles migrations:$pending"
  echo "See ~/dotfiles/docs/migrations/"
fi

# Migrations

One-time steps a Mac needs after pulling a change that stow and the Brewfile
can't apply on their own: removing a tool, moving a file, a manual setting.

- One file per change: `NNNN-short-name.md`, numbered in order, lowercase
  letters, digits and dashes only (other names are skipped).
- Each file lists its steps and ends with the command that marks it done.
- Which migrations a Mac has applied is recorded outside the repo, in
  `~/.local/state/dotfiles/applied-migrations`, one name per line.

`.claude/hooks/pending-migrations.sh` compares the two. Claude Code runs it at
session start and is told about anything pending; the git `post-merge` hook
prints the same list after `git pull`.

```bash
~/dotfiles/.claude/hooks/pending-migrations.sh            # list pending
~/dotfiles/.claude/hooks/pending-migrations.sh done NAME  # mark NAME applied
```

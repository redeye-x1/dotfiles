# Bringing another Mac up to date

Written 2026-11-01 after the cleanup on the main Mac. Run this once on every
other Mac that uses these dotfiles. Afterwards `git pull` keeps it in sync.

## 1. Quit apps that rewrite their settings

Quit **T3 Code** (and Claude Code sessions, if you can). When a linked settings
file disappears for a moment, these apps write a fresh, incomplete one in its
place, and stow then refuses to link.

## 2. Pull

```bash
cd ~/dotfiles && git pull
```

## 3. Remove links stow doesn't own

Stow only manages relative links it created itself. Older absolute links into
the repo block it. List them:

```bash
find ~ -maxdepth 3 -path ~/Library -prune -o -type l -lname "$HOME/dotfiles/*" -print 2>/dev/null
```

Delete each one it prints with `rm <path>`. They only point into the repo, so
nothing is lost.

Then remove the T3 files stow should link instead (T3 must be quit):

```bash
rm -f ~/.t3/userdata/{settings,client-settings,keybindings}.json
```

## 4. Stow

```bash
cd ~/dotfiles
stow -n -v .   # dry run: shows conflicts, changes nothing
stow .
```

If the dry run reports `cannot stow ... over existing target`, that path is a
real file. Compare it with the repo version, keep what you need in the repo,
move the local file to the Trash (`trash <path>`), and run the dry run again.

## 5. Install and remove packages

```bash
brew bundle --file ~/dotfiles/Brewfile
```

This installs what is new in the Brewfile, including **OrbStack** (replaces
Docker Desktop and Podman), `gh`, `unzip`, `python@3.12` and the JetBrains Mono
Nerd Font.

These were dropped from the setup. Remove them if this Mac still has them:

| What | How |
|---|---|
| Podman | `podman machine rm -f && brew uninstall podman` (export volumes first if you need their data) |
| yazi | `brew uninstall yazi` |
| bats-core | `brew uninstall bats-core` |
| bitwarden-cli | `brew uninstall bitwarden-cli` |
| Docker Desktop | Quit it, move `Docker.app` to the Trash, then `sudo rm /usr/local/bin/{docker,docker-compose,docker-credential-desktop,docker-credential-osxkeychain,hub-tool,kubectl,kubectl.docker}` |
| Bitwarden app | Drag `Bitwarden.app` to the Trash |

Open OrbStack once to finish its setup, then open a new terminal.

## 6. Check

```bash
cd ~/dotfiles && git status            # should show nothing unexpected
readlink ~/.t3/userdata/settings.json  # ../../dotfiles/.t3/userdata/settings.json
readlink ~/.claude/CLAUDE.md           # ../dotfiles/.claude/CLAUDE.md
```

Start T3 Code. Its settings, client settings and keybindings now come from the
repo, and changes made in the app are written back into it.

## What changed, in short

- New global `~/.claude/CLAUDE.md`, plus a `reviewer` subagent (Opus, medium effort).
- Claude Code: commit/PR attribution off, the browser-use plugin disabled.
- T3 Code settings live in `.t3/userdata/`.
- SSH keys are no longer fetched from Bitwarden; copy them into `~/.ssh` by hand.
- The herdr hooks with `/Users/mago` paths were removed from Claude settings.
  Re-add them with `~` paths if this Mac still uses herdr.
- `.ssh/config` includes `~/.ssh/conductor_config` (was an absolute path) and
  OrbStack's SSH config.

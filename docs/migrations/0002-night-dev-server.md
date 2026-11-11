# 0002: Home dev server "night"

Written 2026-11-09 on the main Mac. Run this once on every other Mac that
uses these dotfiles, so it can work on `night`.

## What night is

A Linux PC at home that runs 24/7 as the shared development machine. Agents,
dev servers and Docker run there; the Macs are the screens.

- Ubuntu Server 26.04, Ryzen 7 3700X, 32 GB RAM, RTX 2070 Super, 500 GB SSD
- Reachable **only through Tailscale** (tailnet `tail4aad3f.ts.net`). Nothing
  is open to the internet; on the home LAN only SSH is open.
- SSH user `red`, **key login only** (passwords are off). The `Host night`
  entry in `.ssh/config` covers it: `ssh night`.
- Power: short press on the power button boots (about a minute until
  everything is up) or shuts down cleanly. No Wake-on-LAN from outside
  (Magenta DS-Lite), so it can only be switched on at home.

Services, all started on boot:

| What | Where |
|---|---|
| T3 Code server (user service `t3`) | `https://night.tail4aad3f.ts.net` |
| Desktop with Google Chrome (TigerVNC, XFCE) | `vnc://night` |
| Same desktop in a browser (noVNC, also for iPad) | `http://night` |
| Docker 29 + Compose, gh, git, Node LTS + npm, Bun (via mise) | — |
| Claude Code, Proton Pass CLI (`pass-cli`, logged in) | — |

Folder layout on night:

```
~/work/        employer projects (Forgejo)
~/exponent/    Exponent, same paths as on the main Mac:
               website-2026, seo-app, tools, kunden, code/phonefactory, code/enkebora
~/projects/    private products (moby-notes)
```

GitHub (`redeye-x1`, private repos) is the hub between the Macs and night,
except `kunden` (client data), which is never pushed to GitHub; it syncs
between the main Mac and night over SSH (`git push night`).

## 1. Tailscale

```bash
cd ~/dotfiles && git pull
brew bundle --file ~/dotfiles/Brewfile
```

Open Tailscale, log in with the same account as the main Mac, and check that
`night` shows up: `tailscale status | grep night`.

## 2. Give this Mac SSH access to night

night accepts keys only, so this Mac can't add its own key. Use this Mac's own
key, never a copy of another Mac's:

```bash
ls ~/.ssh/id_ed25519.pub || ssh-keygen -t ed25519 -C "$(whoami)@$(scutil --get LocalHostName)"
cat ~/.ssh/id_ed25519.pub
```

Hand the printed public key to the main Mac (it appends it to
`~/.ssh/authorized_keys` on night). Then test from here: `ssh night hostname`
must print `night`.

## 3. Link night in T3 Code

Create a pairing code (valid 5 minutes, never paste it into a chat). The double
quotes matter: `scutil` has to run on this Mac, not on night:

```bash
ssh night "~/.local/bin/t3 pair --tailscale --label $(scutil --get LocalHostName)"
```

In T3 Code on this Mac, add it under **Environments**, with the address
`https://night.tail4aad3f.ts.net` and the code. Not under "Linked
environments": that links night as an agent ("bot"), and creating projects on
night then fails.

T3 client and server versions must match. If this Mac's T3 is newer, run
`t3 update` on night and point `~/.local/bin/t3` at the new version in
`~/.t3/runtime/versions/`, then `systemctl --user restart t3`.

## 4. Work projects (Forgejo)

Already set up on night (2026-11-11); nothing to do per Mac. For reference:

- Work code lives in `~/work/` on night, cloned from the employer's Forgejo
  (`saga.vega-dev.at`) with the same git identity as everywhere else.
- saga has no Git over SSH, only HTTPS. The token is scoped to saga alone:
  `credential.https://saga.vega-dev.at.helper` stores it in
  `~/.git-credentials-saga`, so private GitHub stays untouched.
- `fj` (forgejo-cli) is logged in for PRs; the `@vega` npm token is in
  night's `~/.npmrc`.
- Atlassian MCP is configured for `~/work` only (`~/work/.mcp.json`), not
  globally.
- How to run the Lyra/Nova stack there: `~/work/docs/specs/2026-09-28-driver-module-handoff.md`,
  section "On night".

## 5. Things to know

- Proton Pass on night is logged in with access to all vaults (the owner's
  choice). Anything running as `red` can read them.
- Unattended upgrades cover Ubuntu, Chrome, Docker, Tailscale and gh.
- Never paste passwords or tokens into a chat; use T3's secret prompt.

## Mark as done

```bash
~/dotfiles/.claude/hooks/pending-migrations.sh done 0002-night-dev-server
```

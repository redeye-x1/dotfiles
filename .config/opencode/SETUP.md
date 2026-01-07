# OpenCode + BMAD Setup Instructions

Quick setup guide for your BMAD Method configuration in dotfiles.

## Prerequisites

1. **OpenCode installed**: 
   ```bash
   brew install opencode
   # or
   curl -fsSL https://opencode.ai/install | bash
   ```

2. **GNU Stow installed** (for dotfiles management):
   ```bash
   brew install stow
   ```

## Installation Steps

### 1. Symlink OpenCode Config (First Time)

From your dotfiles directory:

```bash
cd ~/dotfiles
stow -v .config
```

This creates symlinks from `~/.config/opencode/` to your dotfiles.

**Verify**:
```bash
ls -la ~/.config/opencode
# Should show symlink to ~/dotfiles/.config/opencode
```

### 2. Test the Configuration

```bash
cd ~/some-project
opencode
```

Then try:
```
/bmad-help
```

You should see the BMad Master agent respond with methodology guidance.

### 3. Start Your First BMAD Project

In any project directory:

```bash
opencode
```

Then run:
```
/bmad-init
```

Follow the Analyst agent's guidance to initialize your workflow.

## What Gets Synced

Your dotfiles include:

```
.config/opencode/
├── opencode.json          # ✅ Tracked in git
├── bmad-rules.md          # ✅ Tracked in git
├── README.md              # ✅ Tracked in git
├── QUICK-REFERENCE.md     # ✅ Tracked in git
├── SETUP.md               # ✅ Tracked in git (this file)
├── agent/                 # ✅ All agents tracked
└── command/               # ✅ All commands tracked

# NOT in git (via .gitignore):
├── sessions/              # ❌ Local only
├── history/               # ❌ Local only
└── .cache/                # ❌ Local only
```

## Setting Up on Additional Machines

1. Clone your dotfiles:
   ```bash
   git clone <your-dotfiles-repo> ~/dotfiles
   ```

2. Run stow:
   ```bash
   cd ~/dotfiles
   stow -v .config
   ```

3. Install OpenCode:
   ```bash
   brew install opencode
   ```

4. Test:
   ```bash
   opencode
   /bmad-help
   ```

That's it! Your BMAD agents are ready.

## Customization

### Customize an Agent

1. Edit the agent in your dotfiles:
   ```bash
   vim ~/dotfiles/.config/opencode/agent/bmad-dev.md
   ```

2. Changes are immediately available (symlinked!)

3. Commit to git:
   ```bash
   cd ~/dotfiles
   git add .config/opencode/agent/bmad-dev.md
   git commit -m "Customize DEV agent for TypeScript focus"
   git push
   ```

4. Pull on other machines:
   ```bash
   cd ~/dotfiles
   git pull
   ```

### Add New Agents

Create new agents in your dotfiles:

```bash
cat > ~/dotfiles/.config/opencode/agent/my-custom-agent.md <<'EOF'
---
description: My custom agent for specific tasks
mode: subagent
temperature: 0.3
tools:
  write: true
  edit: true
  bash: false
---

# My Custom Agent

Your agent instructions here...
EOF
```

Commit and sync:
```bash
cd ~/dotfiles
git add .config/opencode/agent/my-custom-agent.md
git commit -m "Add custom agent"
git push
```

### Add Custom Commands

```bash
cat > ~/dotfiles/.config/opencode/command/my-command.md <<'EOF'
---
description: My custom command
agent: bmad-dev
---

Your command template here with $ARGUMENTS
EOF
```

## Project-Specific Overrides

You can still have project-specific agents:

```bash
cd your-project
mkdir -p .opencode/agent

# Create project-specific agent
cat > .opencode/agent/project-specific.md <<'EOF'
---
description: Agent specific to this project
mode: subagent
---

Project-specific instructions...
EOF
```

Project agents take precedence over global ones.

## Troubleshooting

### "Agent not found"

Check symlink:
```bash
ls -la ~/.config/opencode
# Should point to ~/dotfiles/.config/opencode
```

Re-stow if needed:
```bash
cd ~/dotfiles
stow -R .config
```

### "Stow conflicts"

If you already have `.config/opencode/`, backup and remove:
```bash
mv ~/.config/opencode ~/.config/opencode.backup
cd ~/dotfiles
stow -v .config
```

### "Commands not working"

Ensure OpenCode can see commands:
```bash
ls -la ~/.config/opencode/command/
```

Try invoking directly:
```bash
@bmad-analyst workflow-init
```

### "Updates not syncing"

After pulling dotfiles updates:
```bash
cd ~/dotfiles
stow -R .config  # Re-stow to update symlinks
```

## Updating

### Update BMAD Agents

1. Edit in your dotfiles
2. Test locally
3. Commit and push
4. Pull on other machines

### Update OpenCode

```bash
brew upgrade opencode
# or
opencode update
```

Your agent configuration persists through OpenCode updates!

## Quick Reference

**Start new project**: `/bmad-init`  
**Check status**: `/bmad-status`  
**Get help**: `/bmad-help`  
**Next story**: `/bmad-next-story`

**Full documentation**: `~/.config/opencode/README.md`  
**Quick reference**: `~/.config/opencode/QUICK-REFERENCE.md`  
**BMAD rules**: `~/.config/opencode/bmad-rules.md`

## Resources

- [OpenCode Docs](https://opencode.ai/docs)
- [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD)
- [BMAD Discord](https://discord.gg/gk8jAdXWmj)

---

**You're all set!** Your BMAD agents are now part of your dotfiles and will follow you everywhere.

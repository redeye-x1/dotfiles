# OpenCode + BMAD Method Configuration

This directory contains OpenCode configuration with integrated BMAD (Build More, Architect Dreams) Method agents for AI-powered agile development.

## What is BMAD Method?

BMAD Method is a comprehensive AI-driven development framework with specialized agents for each phase of software development. It scales from quick bug fixes to enterprise platforms through three planning tracks:

- **Quick Flow**: Bug fixes, small features (tech-spec only)
- **BMad Method**: Products, platforms (PRD + Architecture + UX)
- **Enterprise**: Compliance, scale (full governance)

[Learn more about BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD)

## Directory Structure

```
.config/opencode/
├── opencode.json          # Main OpenCode configuration
├── agent/                 # BMAD agent definitions
│   ├── bmad-analyst.md    # Phase 1: Workflow init, tracking
│   ├── bmad-pm.md         # Phase 2: Requirements, epics
│   ├── bmad-ux-designer.md # Phase 2: UX design
│   ├── bmad-architect.md  # Phase 3: System architecture
│   ├── bmad-sm.md         # Phase 4: Sprint management
│   ├── bmad-dev.md        # Phase 4: Implementation
│   └── bmad-master.md     # Coordinator & methodology guide
├── command/               # Quick workflow commands
│   ├── bmad-init.md       # Initialize new project
│   ├── bmad-status.md     # Check workflow status
│   ├── bmad-help.md       # BMAD methodology help
│   └── bmad-next-story.md # Create next story
└── README.md             # This file
```

## Quick Start

### 1. Setup with GNU Stow

Since this is in your dotfiles, use Stow to symlink to `~/.config/opencode/`:

```bash
cd ~/dotfiles
stow -v .config
```

This will create symlinks from `~/.config/opencode/` to your dotfiles.

### 2. Start a New BMAD Project

In any project directory with OpenCode:

```bash
opencode
```

Then run:
```
/bmad-init
```

Or invoke the Analyst agent directly:
```
@bmad-analyst workflow-init
```

### 3. Follow the BMAD Workflow

The framework will guide you through:
1. **Phase 1** (Optional): Analysis & brainstorming
2. **Phase 2** (Required): Requirements (PRD or tech-spec)
3. **Phase 3** (Track-dependent): Architecture & planning
4. **Phase 4** (Required): Story-driven implementation

Check status anytime:
```
/bmad-status
```

## BMAD Agents

### Phase 1: Analysis (Optional)
- **@bmad-analyst** - Initialize workflows, track progress, facilitate brainstorming

### Phase 2: Planning (Required)
- **@bmad-pm** - Create PRDs, tech specs, manage epics and stories
- **@bmad-ux-designer** - Design user interfaces and experiences (if UI project)

### Phase 3: Solutioning (Track-dependent)
- **@bmad-architect** - Design system architecture, validate readiness

### Phase 4: Implementation (Required)
- **@bmad-sm** - Manage sprints, create stories, provide context
- **@bmad-dev** - Implement stories, review code, write tests

### Coordinator
- **@bmad-master** - Methodology guidance, troubleshooting, best practices

## Quick Commands

These commands are available via `/command-name`:

- `/bmad-init` - Initialize new BMAD project
- `/bmad-status` - Check current workflow status
- `/bmad-help` - Get BMAD methodology guidance
- `/bmad-next-story` - Create and implement next story

## The BMAD Workflow

### Visual Overview

```
Phase 1: Analysis (Optional)
  ↓ @bmad-analyst
  └─→ Brainstorm, Research, Product Brief

Phase 2: Planning (Required)
  ↓ @bmad-pm, @bmad-ux-designer
  ├─→ Quick Flow: tech-spec
  └─→ Method/Enterprise: PRD + UX

Phase 3: Solutioning (Track-dependent)
  ↓ @bmad-architect, @bmad-pm
  ├─→ Architecture
  ├─→ Create Epics & Stories (AFTER architecture!)
  └─→ Implementation Readiness Check

Phase 4: Implementation (Required)
  ↓ @bmad-sm, @bmad-dev
  ├─→ Sprint Planning (once)
  ├─→ Epic Tech Context (per epic)
  └─→ For each story:
      ├─→ Create Story (@bmad-sm)
      ├─→ Story Context (@bmad-sm, optional)
      ├─→ Implement (@bmad-dev)
      └─→ Code Review (@bmad-dev, optional)
```

## Key BMAD Principles

### 1. Fresh Chats
Start each workflow in a new chat to prevent context issues and hallucinations.

### 2. One Story at a Time
Create and complete one story before moving to the next. This prevents chaos.

### 3. Track-Adaptive
Different tracks have different requirements. Let BMAD recommend the right track.

### 4. Architecture-Informed Stories
Stories are created AFTER architecture (v6 improvement) for better quality.

### 5. Context is King
Use epic-tech-context and story-context workflows to provide DEV with focused guidance.

## Configuration

### Main Config: opencode.json

The main configuration file includes:
- Global OpenCode settings
- Permission controls
- Default agent configurations

### Agent Customization

You can customize any agent by editing their `.md` files in the `agent/` directory:

```markdown
---
description: Agent description
mode: subagent
temperature: 0.3
tools:
  write: true
  edit: true
  bash: false
---

Agent instructions and personality...
```

### Custom Commands

Add your own commands in the `command/` directory:

```markdown
---
description: Command description
agent: bmad-agent-name
---

Command template with $ARGUMENTS...
```

## BMAD vs Traditional OpenCode Agents

### Traditional OpenCode
- **build** agent: Full development work
- **plan** agent: Read-only analysis
- **general** subagent: Research and search

### BMAD Method (This Config)
- **Specialized agents** for each phase
- **Structured workflows** following agile methodology
- **Phase-based progression** from analysis to implementation
- **Track-adaptive** planning depth
- **Methodology guidance** via BMad Master

You can use both! BMAD agents complement OpenCode's built-in agents.

## Integration with Dotfiles

### Why in Dotfiles?
- **Version controlled** - Track changes to your agents
- **Portable** - Available on all your machines
- **Shareable** - Team members can use your configuration
- **Update-safe** - Your customizations persist through OpenCode updates

### Updating BMAD Agents

Since these are in your dotfiles:
1. Edit agents in `~/dotfiles/.config/opencode/agent/`
2. Commit changes to git
3. Changes are immediately available to OpenCode
4. Sync across machines with git pull

### Per-Project Overrides

You can still override agents per-project:
```
project/
├── .opencode/
│   ├── agent/           # Project-specific agents
│   └── opencode.json    # Project-specific config
```

Project-specific agents take precedence over global ones.

## Troubleshooting

### Agent not found
Make sure OpenCode can read `~/.config/opencode/`. Check symlinks:
```bash
ls -la ~/.config/opencode
```

### Workflows not working
Ensure you're invoking the correct agent:
- Check workflow status: `/bmad-status`
- Verify agent exists: `ls ~/.config/opencode/agent/`
- Try @mentioning directly: `@bmad-analyst help`

### Context issues
Remember to use fresh chats for each workflow:
1. Complete current workflow
2. Start NEW chat
3. Load appropriate agent
4. Run next workflow

## Resources

- [BMAD Method GitHub](https://github.com/bmad-code-org/BMAD-METHOD)
- [BMAD Documentation](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/src/modules/bmm/docs/README.md)
- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode Agents Guide](https://opencode.ai/docs/agents)
- [BMAD Discord Community](https://discord.gg/gk8jAdXWmj)

## Contributing

Found improvements for the agents? Submit them to your dotfiles repo and share with the team!

---

**Build More, Architect Dreams** with OpenCode and BMAD Method!

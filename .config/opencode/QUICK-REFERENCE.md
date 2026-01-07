# BMAD Method Quick Reference

## Quick Start

```bash
# 1. Initialize project
/bmad-init
# or: @bmad-analyst workflow-init

# 2. Check status anytime
/bmad-status
# or: @bmad-analyst workflow-status

# 3. Get help
/bmad-help
# or: @bmad-master help
```

## The 6 Core Agents

| Agent | Phase | Purpose | Key Workflows |
|-------|-------|---------|---------------|
| **@bmad-analyst** | 1 | Init, track, brainstorm | workflow-init, workflow-status, brainstorm |
| **@bmad-pm** | 2 | Requirements, epics | prd, tech-spec, create-epics-and-stories |
| **@bmad-ux-designer** | 2 | UI/UX design | ux, design-review |
| **@bmad-architect** | 3 | Architecture | create-architecture, implementation-readiness |
| **@bmad-sm** | 4 | Sprint management | sprint-planning, create-story, epic-tech-context |
| **@bmad-dev** | 4 | Implementation | dev-story, code-review |

**Special**: **@bmad-master** - Methodology guidance, no implementation

## The 4 Phases

```
Phase 1: Analysis (Optional)
  └─ Brainstorm, Research, Product Brief
  
Phase 2: Planning (Required)
  ├─ Quick Flow: tech-spec only
  └─ Method/Enterprise: PRD + UX
  
Phase 3: Solutioning (Track-dependent)
  ├─ Architecture (Method/Enterprise only)
  ├─ Create Epics & Stories
  └─ Implementation Readiness
  
Phase 4: Implementation (Required)
  └─ Story-by-story development
```

## The 3 Planning Tracks

| Track | When | Planning Docs | Stories |
|-------|------|---------------|---------|
| **Quick Flow** | Bug fixes, small features | tech-spec only | 1-15 |
| **BMad Method** | Products, platforms | PRD + Architecture + UX | 10-50+ |
| **Enterprise** | Compliance, scale | Full governance | 30+ |

*Story counts are guidance, not strict rules*

## Common Workflows by Phase

### Phase 1: Analysis (All Optional)
```
@bmad-analyst
  - brainstorm-project
  - research
  - product-brief
```

### Phase 2: Planning
```
@bmad-pm
  - prd (Method/Enterprise)
  - tech-spec (Quick Flow)
  - create-epics-and-stories (after Phase 3!)

@bmad-ux-designer
  - ux (if UI project)
```

### Phase 3: Solutioning
```
@bmad-architect
  - create-architecture (Method/Enterprise)
  - implementation-readiness (validation)

@bmad-pm
  - create-epics-and-stories (NOW - after architecture!)
```

### Phase 4: Implementation
```
@bmad-sm
  - sprint-planning (once)
  - epic-tech-context (per epic, optional)
  - create-story (per story)
  - story-context (per story, optional)
  - retrospective (per epic)

@bmad-dev
  - dev-story (per story)
  - code-review (per story, optional)
```

## Story Implementation Loop

```
1. SM: create-story         (new chat)
2. SM: story-context        (new chat, optional)
3. DEV: dev-story           (new chat)
4. DEV: code-review         (new chat, optional)
5. Repeat for next story
```

## The Golden Rules

### 1. Fresh Chats
- Start EVERY workflow in a new chat
- Prevents context overflow
- Reduces hallucinations

### 2. One Story at a Time
- Create one story
- Implement it completely
- Only then create next story
- Prevents chaos and context switching

### 3. Check Status First
```
/bmad-status
```
When unsure what to do next, always check status.

### 4. Follow the Track
- Quick Flow: Faster, less ceremony
- BMad Method: Full planning
- Enterprise: Extended governance

### 5. Architecture Before Stories
V6 improvement: Create stories AFTER architecture for better quality.

## Quick Commands

| Command | Does |
|---------|------|
| `/bmad-init` | Initialize new project |
| `/bmad-status` | Check workflow status |
| `/bmad-help` | Get methodology help |
| `/bmad-next-story` | Create next story |

## Agent Invocation

Three ways to invoke agents:

```bash
# 1. Via command (if command exists)
/bmad-init

# 2. Via @mention
@bmad-analyst workflow-init

# 3. Natural language with @mention
@bmad-pm let's create a PRD
```

## File Outputs

BMAD creates these files:

### Phase Tracking
- `bmm-workflow-status.yaml` - Phase and workflow tracking (created by workflow-init)
- `sprint-status.yaml` - Sprint and story tracking (created by sprint-planning)

### Planning Documents
- `PRD.md` - Product Requirements (BMad Method/Enterprise)
- `tech-spec.md` - Technical Spec (Quick Flow)
- `UX-Design.md` - UX Specification (if UI project)
- `Architecture.md` - System Architecture (BMad Method/Enterprise)

### Implementation
- `Epic-{name}/` - Epic folders with stories
- `Story-{id}.md` - Individual story files

## Typical Project Flow

### Quick Flow Track (Simple)
```
1. @bmad-analyst: workflow-init
2. @bmad-pm: tech-spec
3. @bmad-sm: sprint-planning
4. For each story:
   - @bmad-sm: create-story
   - @bmad-dev: dev-story
```

### BMad Method Track (Standard)
```
1. @bmad-analyst: workflow-init
2. @bmad-pm: prd
3. @bmad-ux-designer: ux (if UI)
4. @bmad-architect: create-architecture
5. @bmad-pm: create-epics-and-stories
6. @bmad-architect: implementation-readiness
7. @bmad-sm: sprint-planning
8. For each epic:
   - @bmad-sm: epic-tech-context
   - For each story:
     - @bmad-sm: create-story
     - @bmad-sm: story-context (optional)
     - @bmad-dev: dev-story
     - @bmad-dev: code-review (optional)
   - @bmad-sm: retrospective
```

## When Things Go Wrong

### "I don't know what to do next"
```
/bmad-status
```

### "The agent seems confused"
- Start a fresh chat
- Re-invoke the agent
- Try the workflow again

### "I need to change scope"
```
@bmad-pm correct-course
```

### "I need methodology help"
```
/bmad-help
# or
@bmad-master help with [your question]
```

### "Agent not found"
Check OpenCode can see agents:
```bash
ls -la ~/.config/opencode/agent/
```

## Pro Tips

1. **Use Tab completion** - OpenCode supports tab completion for @mentions
2. **Be specific** - "Let's create a PRD" works better than "help"
3. **Check examples** - Each agent has examples in their .md file
4. **Customize agents** - Edit agent .md files to fit your style
5. **Use BMad Master** - When unsure, ask @bmad-master for guidance

## Resources

- Full README: `.config/opencode/README.md`
- BMAD Method: https://github.com/bmad-code-org/BMAD-METHOD
- OpenCode Docs: https://opencode.ai/docs
- BMAD Discord: https://discord.gg/gk8jAdXWmj

---

**Remember**: Fresh chats, one story at a time, check status when unsure!

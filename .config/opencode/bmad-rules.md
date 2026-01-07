# BMAD Method Rules and Best Practices

These rules ensure successful AI-driven development with the BMAD Method.

## Core Principles

### 1. Fresh Chat Discipline
- Start EVERY workflow in a new chat session
- This prevents context overflow and hallucinations
- Context is precious - don't waste it on accumulated conversation history

### 2. One Story at a Time
- Create ONE story, implement it COMPLETELY, then move to the next
- Never create multiple stories in advance
- This prevents scope creep and context switching

### 3. Track-Appropriate Planning
- **Quick Flow**: Minimal ceremony, tech-spec only
- **BMad Method**: Full planning with PRD and architecture
- **Enterprise**: Extended governance and compliance
- Don't over-engineer small features, don't under-plan large systems

### 4. Architecture Before Stories (V6)
- In Phase 3, ALWAYS create architecture BEFORE epics and stories
- Architecture decisions inform how stories should be broken down
- This is a V6 improvement that significantly improves story quality

### 5. Follow the Status
- When unsure what to do next, check workflow-status
- Don't guess or skip ahead
- The status file is the source of truth

## Agent-Specific Rules

### @bmad-analyst
- Always the entry point for new projects (workflow-init)
- Provides objective workflow status when asked
- Does NOT implement - guides to appropriate agent

### @bmad-pm
- Owns all requirements and scope
- Creates epics/stories AFTER architecture (Phase 3, not Phase 2)
- Consults with Architect on technical feasibility

### @bmad-ux-designer
- Only involved if project has user interface
- Works from PRD requirements
- Provides clear implementation specs for DEV

### @bmad-architect
- Designs patterns BEFORE implementation starts
- Provides clear implementation examples
- Validates implementation readiness before Phase 4

### @bmad-sm
- Orchestrates implementation phase
- Creates context (epic and story level) to guide DEV
- Updates sprint-status after every workflow

### @bmad-dev
- Implements ONE story at a time
- ALWAYS follows architecture patterns
- Updates sprint-status when story complete
- Never invents new patterns without consulting Architect

### @bmad-master
- Read-only advisor and guide
- Never implements code
- Provides methodology expertise

## Workflow Rules

### Phase Progression
1. Must complete workflow-init before starting Phase 1 or 2
2. Must complete Phase 2 before Phase 3
3. Must complete Phase 3 before Phase 4 (for Method/Enterprise tracks)
4. Cannot skip required phases for your track

### Story Creation
1. Stories created in Phase 3 AFTER architecture
2. Stories created ONE AT A TIME in Phase 4
3. Story must be fully implemented before creating next story
4. No story creation without PRD/tech-spec

### Context Management
1. epic-tech-context is optional but recommended (start of epic)
2. story-context is optional but recommended (before dev-story)
3. Both prevent repetitive codebase analysis
4. Both reduce hallucinations

## Quality Rules

### Code Quality
- Follow architecture patterns defined in Architecture.md
- Write tests for all new code
- Handle errors explicitly, never fail silently
- Keep functions small and focused (< 20 lines ideal)

### Documentation
- Update technical docs when architecture changes
- Document WHY in comments, not WHAT
- Keep README current
- Include examples for complex features

### Testing
- Unit tests for business logic
- Integration tests for workflows
- Test edge cases and error conditions
- Maintain > 80% coverage for critical paths

## Anti-Patterns to Avoid

### ❌ DON'T: Create all stories upfront
- ✅ DO: Create one story at a time

### ❌ DON'T: Keep using same chat for multiple workflows
- ✅ DO: Start fresh chat for each workflow

### ❌ DON'T: Skip architecture for medium/large projects
- ✅ DO: Create architecture for BMad Method and Enterprise tracks

### ❌ DON'T: Invent new patterns during implementation
- ✅ DO: Follow patterns defined in Architecture.md

### ❌ DON'T: Create stories before architecture
- ✅ DO: Wait until Phase 3, AFTER architecture is complete

### ❌ DON'T: Mix multiple agents in one chat
- ✅ DO: Use one agent per chat, switch agents in new chats

### ❌ DON'T: Edit workflow status files manually
- ✅ DO: Let agents update status files automatically

## File Management Rules

### Status Files
- `bmm-workflow-status.yaml` - NEVER edit manually
- `sprint-status.yaml` - NEVER edit manually
- Agents update these automatically

### Planning Documents
- `PRD.md` - Single source of truth for requirements
- `Architecture.md` - Single source of truth for technical decisions
- Keep these updated if scope changes (via correct-course workflow)

### Story Files
- One file per story
- Follow naming convention: `Story-{epic}-{number}.md`
- Include acceptance criteria
- Reference architecture patterns

## Git and Version Control

### What to Commit
- All planning documents (PRD, Architecture, UX, etc.)
- All story files
- Status files (bmm-workflow-status.yaml, sprint-status.yaml)
- Implementation code and tests

### Commit Frequency
- After each completed workflow
- After each completed story
- Before starting new phase
- After retrospectives

### Commit Messages
- Reference story IDs in commits
- Use conventional commit format
- Include context for future reference

## Communication Rules

### With Agents
- Be specific about what you want
- Provide context and constraints
- Ask clarifying questions
- Give feedback on outputs

### Error Handling
- If agent seems confused, start fresh chat
- If workflow fails, check prerequisites
- If unsure, ask @bmad-master for guidance

## Performance Optimization

### Context Efficiency
- Use fresh chats to maximize available context
- Use epic-tech-context to avoid repetitive analysis
- Use story-context for focused implementation guidance
- Keep planning documents concise

### Workflow Efficiency
- Batch similar work (all brainstorming in Phase 1)
- Don't context switch between stories
- Complete current phase before jumping ahead
- Use retrospectives to improve process

## Security and Privacy

### Sensitive Data
- Never commit secrets or credentials
- Use environment variables for configuration
- Review code for exposed sensitive information
- Use .gitignore for local-only files

### Code Review
- Always run code-review workflow (optional but recommended)
- Check for security vulnerabilities
- Validate input sanitization
- Review authentication/authorization logic

## Scaling Guidelines

### Small Projects (1-10 stories)
- Quick Flow track recommended
- Minimal ceremony
- Focus on delivery speed

### Medium Projects (10-50 stories)
- BMad Method track recommended
- Full planning and architecture
- Balance speed with quality

### Large Projects (50+ stories)
- Enterprise track recommended
- Extended governance
- Focus on maintainability and scalability

### Very Large Projects (100+ stories)
- Break into multiple sub-projects
- Each can use appropriate track
- Coordinate via shared architecture

## Continuous Improvement

### Retrospectives
- Run after each epic completion
- Identify what worked well
- Identify what needs improvement
- Update processes based on learnings

### Customization
- Customize agent personalities in .md files
- Add project-specific rules to .opencode/
- Create custom commands for common workflows
- Share improvements with team

## Getting Help

### When Stuck
1. Check `/bmad-status` for next step
2. Review `QUICK-REFERENCE.md` for workflow guidance
3. Ask `@bmad-master` for methodology help
4. Check BMAD documentation
5. Ask in Discord community

### Reporting Issues
- Agent bugs: OpenCode GitHub issues
- BMAD methodology: BMAD-METHOD GitHub issues
- Questions: Discord #general-dev channel

---

**Remember**: These rules exist to prevent chaos and ensure quality. Follow them for successful AI-driven development!

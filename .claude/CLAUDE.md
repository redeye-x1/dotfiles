# Response language

Always respond in English, regardless of the language of my prompt.

Note: the `language: "German"` setting in `settings.json` is intentional — it
sets the **voice dictation** language to German (Claude Code couples voice and
response language via one setting). This instruction overrides the response
language back to English. Voice input stays German; text answers are English.

# Subagents

- Delegate independent read-only work (codebase searches, research, docs
  lookups, reviews) to subagents on your own, in parallel when the pieces are
  independent. Keep only their conclusions in the main context.
- Implement code sequentially in the main thread, or one subagent per task
  in order. Don't run several agents writing code in parallel unless I ask;
  if I do, give each its own worktree and clearly separated files.
- Before delegating implementation, write a concrete plan (files, interfaces,
  acceptance criteria) so subagents don't make hidden decisions.
- Verify subagent output (tests, diff review) before reporting it as done.

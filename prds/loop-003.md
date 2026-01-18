# RALPH Git Workflow - PRD

## Overview

RALPH needs clear instructions for when and how to commit changes to git. Git commits provide durable state across agent contexts and create a linear history of autonomous development progress.

## Goals

- RALPH commits changes when PRD execution completes (success or failure)
- RALPH uses consistent commit message format for traceability
- RALPH handles edge cases where no changes exist to commit
- Git history reflects PRD names, statuses, and iteration numbers

## User Stories

- As RALPH, I want to commit after each PRD completes, so that progress is preserved
- As RALPH, I want to use standard commit messages, so that git history is searchable
- As a developer, I want commits for failed PRDs too, so that I can see what didn't work
- As a developer, I want commit messages to reference PRDs, so that I can trace changes back to requirements

## Acceptance Criteria

- [ ] RALPH commits changes when tests pass after REVIEWER approval
- [ ] RALPH commits changes when max iterations (5) reached
- [ ] RALPH skips git commit if no changes exist
- [ ] Commit message includes PRD name, status, and iteration number
- [ ] Commit message includes brief summary of completion
- [ ] RALPH handles git operation errors gracefully
- [ ] Commit occurs before moving to next PRD

## Technical Requirements

### Commit Timing
- After tests pass (successful PRD completion)
- After max iterations reached (failed PRD)

### Commit Message Format
```
[PRD_NAME] [STATUS] iteration [N] - [brief summary]
```

Examples:
- `[hello-world] COMPLETED iteration 3 - Implemented HelloWorld.hello method`
- `[hello-world] FAILED iteration 5 - Max iterations reached, insufficient test coverage`

### Git Operations
- Use existing bash tool for git commands
- Commit with message via `git commit -m "message"`
- Check for staged changes before committing

## Implementation Notes

- Update agents/RALPH.md with "Git Workflow" section
- Define clear subsections: When to Commit, Commit Format, Edge Cases
- Preserve existing RALPH.md content
- Git operations use existing bash tool

## Edge Cases & Error Handling

- No staged changes: Skip git add/commit, don't create empty commit
- Git not initialized: Treat as failure, return error message
- Commit fails (permissions, conflicts): Return FAILURE with error details
- Commit succeeds but PRD update fails: Report FAILURE (status may be stale)

## Testing Requirements

- Manual test: RALPH commits after successful PRD completion
- Manual test: RALPH commits after max iterations (failed PRD)
- Manual test: RALPH skips commit when no changes exist
- Manual test: Verify commit message format matches specification
- Manual test: Verify git error handling (e.g., no .git directory)

## Dependencies

- loop-002 (core orchestration) must be complete
- RALPH.md agent definition exists
- bash tool exists (RALPH already has access)

## Success Criteria

- RALPH commits at appropriate points in the loop
- Commit messages follow consistent format
- Git history is traceable to PRDs
- Edge cases are handled gracefully
- No empty commits are created

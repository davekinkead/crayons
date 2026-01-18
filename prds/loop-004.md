# RALPH PRD State Management - PRD

## Overview

RALPH needs to track PRD progress through statuses and iterations. PRD state provides visibility into what work is done, what's in progress, and what failed. This state enables RALPH to make intelligent PRD selection decisions and helps humans understand autonomous development progress.

## Goals

- RALPH reads PRD status from frontmatter metadata
- RALPH updates PRD status through the development lifecycle
- RALPH tracks iteration count for each PRD
- RALPH records feedback from CODER, REVIEWER, and test runs in PRD files
- PRD files provide a complete history of work attempted on each requirement

## User Stories

- As RALPH, I want to read PRD status, so that I can prioritize planned PRDs
- As RALPH, I want to update PRD status to in_progress when working, so that I don't pick it again
- As RALPH, I want to mark PRDs as completed or failed when done, so that final state is clear
- As RALPH, I want to increment iteration count, so that I track retry attempts
- As a developer, I want feedback recorded in PRDs, so that I understand what went wrong

## Acceptance Criteria

- [ ] RALPH reads PRD frontmatter for status field
- [ ] RALPH reads PRD frontmatter for iteration field
- [ ] RALPH updates PRD status to in_progress when starting work
- [ ] RALPH updates PRD status to completed when tests pass
- [ ] RALPH updates PRD status to failed when max iterations reached
- [ ] RALPH increments iteration counter before each retry
- [ ] RALPH adds feedback entries when CODER fails
- [ ] RALPH adds feedback entries when REVIEWER fails
- [ ] RALPH adds feedback entries when tests fail
- [ ] RALPH adds feedback entries with agent name, iteration, and timestamp

## Technical Requirements

### PRD Frontmatter Fields
- `status`: planned, in_progress, completed, or failed
- `iteration`: integer, starting at 1

### Status Lifecycle
- planned → in_progress → completed or failed

### Feedback History Format
```markdown
## Feedback History

### [Agent Name] (Iteration [N]): [COMPLETE/FAILURE/FAILED]
**Date:** [timestamp]

[Specific feedback or test output]
```

### File Operations
- Use existing read_file, edit_file tools
- Use bash tool if needed for frontmatter manipulation

## Implementation Notes

- Update agents/RALPH.md with "PRD State Management" section
- Define status transitions and when they occur
- Define feedback format and when to add entries
- RALPH can use existing tools to read/edit PRD files
- Frontmatter can be manipulated via edit_file or bash (sed/yq)

## Edge Cases & Error Handling

- PRD missing frontmatter: Treat as status=planned, iteration=1
- PRD has invalid status: Default to planned
- PRD has non-integer iteration: Default to 1
- Feedback History section doesn't exist: Create it
- PRD update fails: Return FAILURE with error details

## Testing Requirements

- Manual test: RALPH reads PRD status correctly
- Manual test: RALPH updates PRD status through lifecycle (planned → in_progress → completed)
- Manual test: RALPH increments iteration counter on retries
- Manual test: RALPH adds feedback entries for CODER failure
- Manual test: RALPH adds feedback entries for REVIEWER failure
- Manual test: RALPH adds feedback entries for test failure
- Manual test: RALPH handles PRDs without frontmatter

## Dependencies

- loop-002 (core orchestration) must be complete
- loop-003 (git workflow) recommended (commit hash can be added to feedback)
- PRDs exist in prds/ directory
- RALPH has read_file, edit_file, bash tools

## Success Criteria

- RALPH tracks PRD status through development lifecycle
- RALPH tracks iteration count for retry logic
- PRD files accumulate feedback history
- Humans can read PRD files to understand what happened
- RALPH uses status to prioritize planned PRDs

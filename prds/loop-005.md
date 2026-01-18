# RALPH Error Handling & Return Format - PRD

## Overview

RALPH needs clear instructions for handling error scenarios and returning completion status. Proper error handling ensures that RALPH fails gracefully and provides useful information when things go wrong. The return format lets humans and other systems know what RALPH accomplished.

## Goals

- RALPH returns COMPLETE when all PRDs are processed
- RALPH returns FAILURE when no PRDs are available
- RALPH returns FAILURE when agent spawning fails
- RALPH returns FAILURE when git operations fail
- RALPH returns detailed information about what was accomplished or what failed

## User Stories

- As a human, I want RALPH to return COMPLETE when finished, so that I know work is done
- As a human, I want RALPH to return FAILURE with details, so that I can troubleshoot
- As RALPH, I want to handle missing PRDs gracefully, so that I don't crash
- As RALPH, I want to handle agent spawn failures, so that the system remains stable
- As RALPH, I want to handle git errors, so that I can report what went wrong

## Acceptance Criteria

- [ ] RALPH returns COMPLETE when all PRDs have completed or failed status
- [ ] RALPH returns FAILURE when prds/ directory is empty or doesn't exist
- [ ] RALPH returns FAILURE when spawn_agent tool fails (invalid agent)
- [ ] RALPH returns FAILURE when git commit operation fails
- [ ] COMPLETE return includes summary of completed PRDs, failed PRDs, and commit hashes
- [ ] FAILURE return includes specific error details
- [ ] Return format uses standard promise tags: `<promise>COMPLETE</promise>` or `<promise>FAILURE: message</promise>`

## Technical Requirements

### Return Format

COMPLETE:
```
<promise>COMPLETE</promise>

Summary:
- Completed: [N] PRDs
- Failed: [N] PRDs
- Commits: [hash1, hash2, ...]
```

FAILURE:
```
<promise>FAILURE: [specific error message]</promise>
```

### Error Scenarios

1. **No PRDs available**
   - prds/ directory doesn't exist
   - prds/ directory has no markdown files
   - All PRDs already have completed/failed status

2. **Agent spawn failure**
   - Invalid agent name
   - Agent file not found
   - Agent initialization error

3. **Git operation failure**
   - Git not initialized
   - Commit fails (permissions, conflicts)
   - Commit hash retrieval fails

### Return Timing

- Return COMPLETE after final PRD completes
- Return FAILURE immediately when blocking error occurs
- Process all PRDs before returning COMPLETE (even if some fail)

## Implementation Notes

- Update agents/RALPH.md with "Return Format" and "Error Handling" sections
- Define clear error conditions and their corresponding FAILURE messages
- Specify COMPLETE summary format
- Integrate error handling into orchestration flow
- RALPH returns after all PRDs are processed (not after each PRD)

## Edge Cases & Error Handling

- All PRDs already completed: Return COMPLETE with summary
- Mix of completed and failed PRDs: Return COMPLETE with summary of both
- First PRD spawn fails: Return FAILURE immediately
- Git commit fails mid-loop: Return FAILURE with details
- No PRDs at start: Return FAILURE immediately

## Testing Requirements

- Manual test: RALPH returns COMPLETE after processing all PRDs
- Manual test: RALPH returns COMPLETE summary includes completed/failed counts
- Manual test: RALPH returns FAILURE when prds/ directory is empty
- Manual test: RALPH returns FAILURE when agent spawn fails
- Manual test: RALPH returns FAILURE when git commit fails
- Manual test: RALPH handles all PRDs already completed scenario
- Manual test: RALPH handles mix of completed and failed PRDs

## Dependencies

- loop-002 (core orchestration) must be complete
- loop-003 (git workflow) must be complete
- loop-004 (PRD state management) must be complete
- All error scenarios must be handled in orchestration logic

## Success Criteria

- RALPH uses standard promise format for all returns
- COMPLETE returns provide useful summary information
- FAILURE returns include specific error details
- RALPH handles all error scenarios gracefully
- No crashes or unhandled exceptions
- Humans can understand what RALPH accomplished or why it failed

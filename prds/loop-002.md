# RALPH Core Orchestration - PRD

## Overview

RALPH needs clear instructions for managing the develop-review loop for each PRD. This includes spawning CODER, spawning REVIEWER, and tracking iteration attempts until success or failure.

## Goals

- RALPH executes the develop-review loop for each PRD
- RALPH tracks iterations to prevent infinite loops
- RALPH delegates implementation to CODER via spawn_agent
- RALPH delegates validation to REVIEWER via spawn_agent
- RALPH determines when to continue vs. move to next PRD

## User Stories

- As RALPH, I want to run the develop-review loop for each PRD, so that implementation and validation occur systematically
- As RALPH, I want to track iterations, so that I don't get stuck on a failing PRD
- As RALPH, I want to delegate to CODER, so that implementation is handled by a specialized agent
- As RALPH, I want to delegate to REVIEWER, so that validation is handled independently
- As a developer, I want PRDs to complete with clear success or failure, so that progress is measurable

## Acceptance Criteria

- [ ] RALPH spawns CODER with PRD content for each selected PRD
- [ ] RALPH checks CODER response (COMPLETE vs FAILURE)
- [ ] RALPH spawns REVIEWER after CODER returns COMPLETE
- [ ] RALPH checks REVIEWER response (COMPLETE vs FAILURE)
- [ ] RALPH tracks iteration count starting at 1
- [ ] RALPH retries the develop-review loop on FAILURE
- [ ] RALPH stops after 5 iterations on a PRD
- [ ] RALPH proceeds to next PRD after 5 failures
- [ ] RALPH proceeds to next PRD after successful completion

## Technical Requirements

- Max iterations per PRD: 5
- Iteration counter starts at 1
- RALPH uses spawn_agent tool to spawn CODER and REVIEWER
- CODER receives full PRD content as instructions
- REVIEWER receives PRD content as instructions
- RALPH parses agent responses for COMPLETE/FAILURE promise tags

## Implementation Notes

- Update agents/RALPH.md with orchestration instructions
- Add "PRD Completion Loop" section to RALPH.md
- Define clear flow: CODER → REVIEWER → retry/continue
- Loop continues until success or max iterations reached

## Edge Cases & Error Handling

- CODER returns FAILURE: RALPH notes failure, increments iteration, retries
- REVIEWER returns FAILURE: RALPH notes failure, increments iteration, retries from CODER
- Max iterations reached: RALPH marks PRD as failed, moves to next PRD
- Agent spawn fails: RALPH treats as FAILURE, retries
- No PRDs available: RALPH returns COMPLETE with summary

## Testing Requirements

- Manual test: RALPH runs loop for simple PRD that succeeds
- Manual test: RALPH runs loop for failing PRD that reaches max iterations
- Manual test: RALPH processes multiple PRDs sequentially
- Manual test: RALPH handles CODER FAILURE correctly
- Manual test: RALPH handles REVIEWER FAILURE correctly
- Verify iteration counter increments correctly
- Verify max iterations prevents infinite loop

## Dependencies

- loop-001 (spawn_agent tool) must be complete
- RALPH agent definition exists (agents/RALPH.md)
- CODER agent definition exists (agents/CODER.md)
- REVIEWER agent definition exists (agents/REVIEWER.md)

## Success Criteria

- RALPH orchestrates CODER and REVIEWER correctly
- Develop-review loop functions as designed
- Iteration counting prevents infinite loops
- PRDs complete with success or failure state
- RALPH can process multiple PRDs in sequence

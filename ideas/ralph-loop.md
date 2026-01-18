# Ralph Loop

## Why This Architecture

The Ralph Loop implements the Ralph Wiggum technique—autonomous software development with human-on-the-loop oversight—using a two-agent system with clear separation of concerns: RALPH (orchestration) and CODER/REVIEWER (development). This separation keeps each agent focused with minimal context, preventing the "smart zone" degradation that occurs when single agents try to do too much.

## Architecture Overview

Agents:
- **RALPH**: Orchestrates PRD selection and execution loop (human calls directly)
- **CODER**: Implements specs and code for a given PRD
- **REVIEWER**: Validates specs against PRD requirements

## Core Principles

- **Planning occurs upfront**: PRDs are created before RALPH runs, outside this system
- **RALPH is pure orchestration**: RALPH does not create PRDs, only executes them
- **Fresh contexts**: Each agent invocation starts clean, no context pollution
- **Specs first**: Coder writes specs from scratch using TDD, then implements code
- **Git as inter-context memory**: Completed PRDs commit immediately for durable state
- **Feedback accumulation**: PRDs capture all agent feedback for next attempts
- **Develop-review loop**: Each PRD goes through iterative develop-review cycles until complete

## Loop Flow

### Ralph Selection
Ralph is spawned with access to available PRDs. He evaluates which PRD to work on next based on dependencies, priority, and current project state.

### PRD Completion Loop
For each selected PRD:
1. Spawn Coder with PRD content
2. Coder writes specs + code, returns status (complete/failure) with message
3. If FAILURE: Update PRD with feedback, retry
4. If COMPLETE: Spawn Reviewer
5. Reviewer validates specs vs PRD + TESTING.md, returns COMPLETE/FAILURE
6. If FAILURE: Update PRD with feedback, retry coder
7. If COMPLETE: Run bundle exec rspec
8. Tests pass? - commit to git, select next PRD
9. Tests fail? - Update PRD with failure details, retry coder
10. Max iterations (5)? - Mark PRD failed, select next PRD

## Agent Roles

### RALPH (Orchestrator)
RALPH reads available PRDs, selects which one to work on next, and manages the develop-review loop. RALPH spawns CODER and REVIEWER agents, monitors their output, runs tests, commits successful PRDs to git, and accumulates feedback in PRDs for retry attempts.

### CODER
Spawned by RALPH with PRD content. Coder reads the PRD, writes specs from scratch following TESTING.md guidelines, implements the code to pass those specs, and returns completion status. Coder focuses on describing behavior through tests, then implementing the minimal code to pass them.

### REVIEWER
Spawned by RALPH after Coder reports completion. Reviewer reads the PRD and the spec files (not the implementation code), validates that all PRD requirements are tested, checks edge cases and error handling, and ensures TESTING.md compliance. Returns COMPLETE if approved, FAILURE with specific feedback if rejected.

## PRD Format

PRDs are markdown files. Format includes frontmatter (iteration, status, created_at), Current Objective, Success Criteria, Verification Steps, and Feedback History section. Status values: planned, in_progress, completed, failed. Feedback history accumulates across iterations with agent name, iteration number, timestamp, and specific feedback.

## Design Decisions

**RALPH as pure orchestrator**: RALPH does not create PRDs, only executes them. This separation keeps planning (strategic) and execution (tactical) distinct.

**Sequential PRDs**: RALPH processes one PRD at a time for simplicity and linear git history. RALPH uses judgment to select the next appropriate PRD.

**Coder writes specs**: Coder knows implementation needs, avoids handoff friction. Reviewer validates spec quality independently.

**Reviewer checks specs only**: Keeps reviewer lightweight, enforces separation of concerns—specs describe behavior, code implements it.

**Git commits on success**: Provides durable state across contexts, linear progress tracking.

**Feedback in PRDs**: Enables debugging, pattern recognition, helps identify recurring issues.

**Max iterations**: Prevents infinite loops. After 5 attempts on a PRD, mark as failed and move on.

## Error Handling

- **RALPH no PRDs**: Return FAILURE if no PRDs available or all completed
- **RALPH max iterations (5)**: Mark PRD as failed, select next PRD
- **Coder failure**: RALPH updates PRD with feedback, retries
- **Reviewer failure**: RALPH updates PRD with feedback, retries coder
- **Test failure**: RALPH updates PRD with test output, retries coder

## Success Criteria

- RALPH selects appropriate PRD when spawned
- RALPH spawns CODER with PRD, coder implements specs + code
- RALPH spawns REVIEWER, validates specs vs PRD
- Tests run after reviewer approval
- Git commits successful PRDs
- RALPH returns FAILURE with details if max iterations hit
- PRD files persist for debugging and pattern recognition

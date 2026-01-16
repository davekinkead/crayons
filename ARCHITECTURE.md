# Architecture of Ralph

Ralph is a Ruby-based autonomous software development system that follows the Ralph Wiggum technique.

## Core Components

### Orchestrator
The main loop controller that:
- Manages iteration cycles
- Decides which agent to invoke
- Monitors context window usage
- Prevents auto-compaction

### Agents
Each agent implements a common interface:
- `verify(context)` - Check if prerequisites are met
- `execute(context)` - Perform the agent's task
- `complete?(context)` - Determine if task is finished

#### Spec Agent
- Phase 1: Generates test descriptions from requirements
- Phase 2: Implements full test suite

#### Coder Agent
- Implements code to pass the specs
- Runs verification after each change

#### Tester Agent
- Runs test suites
- Reports failing cases (never full output)

#### Reviewer Agent
- Reviews code quality
- Checks against architecture constraints

### Context Management

#### Allocator
- Token-aware context management
- Pre-allocates project context
- Monitors usage during iteration
- Never auto-compacts

#### Workspace
- Persistent state storage
- Maintains iteration history
- Stores golden windows

### Tools

#### Bash
- Command execution
- Test running

#### Files
- File I/O operations
- Reading/writing project files

#### Git
- Version control operations
- Commit management

## Data Flow

```
Requirements → Spec Agent → Orchestrator validates → Spec Agent (Phase 2) → Coder Agent → Tester Agent → [Loop until complete] → Reviewer Agent
```

## Context Window Strategy

Each iteration:
1. Pre-allocate: ARCHITECTURE.md, TESTING.md, agent instructions
2. Allocate current goal/objective
3. Allocate working context as needed
4. Never exceed performance line
5. Reset if context grows too large

## Agent Instructions

Each agent reads from `your-project/agents/AGENT_NAME.md` for its specific instructions.

## Verification

All agents must run verification after making changes. The verification command is specified in TESTING.md.

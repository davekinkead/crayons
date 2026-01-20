# Crayons

A Ruby-based autonomous software development system inspired by the Ralph Wiggum technique.

## What is Ralph?

Ralph is a simple but powerful technique for autonomous software development:

1. **One task, one objective per loop iteration** - Don't try to do everything at once
2. **Iterative refinement** - Keep looping until the goal is met
3. **Human ON the loop, not IN the loop** - Observe and steer, don't inject mid-work
4. **Context as an array** - Treat the LLM's context window like a C array: allocate deliberately, monitor usage, stay in the "smart zone"

The technique was pioneered by Geoffrey Huntley and popularized through (mis)demonstrations with Claude Code. This Ruby implementation applies those principles while adding agent-specific context management.

## Core Principles

### 1. Less is More

The transcripts repeatedly emphasize: **less context, better outcomes**.

- Think like a C/C++ engineer: the context window is an array with fixed size
- The LLM slides over this array - the less it needs to slide, the better
- There is no server-side memory - only what's in the context window exists
- Every tool call allocates to the array
- Remove unnecessary content - it pushes important information into the "dumb zone"

### 2. Smart Zone vs Dumb Zone

LLM performance degrades when context grows too large:

```
High Performance (Smart Zone)
│
│  ┌─────────────────────┐
│  │  Deliberate         │  ← Pre-allocated: specs, goals, project context
│  │  Allocation          │
│  └─────────────────────┘
│  ┌─────────────────────┐
│  │  Working Context    │  ← Dynamic: tool calls, file reads, edits
│  │  (varies)           │
│  └─────────────────────┘
│
├─────────────────────────┤  ← Performance Line
│  Dumb Zone               │  ← Context grows, model gets confused
│  (avoid this!)          │
└─────────────────────────┘
```

Goal: keep everything in the smart zone with some headroom for verification.

### 3. No Auto-Compaction

The Anthropic Ralph plugin uses auto-compaction - when context gets too large, it automatically summarizes and compresses. This is **lossy**:

- Can remove specs
- Can lose goals/objectives
- Non-deterministic - you never know what gets kept

This Ruby implementation: **never auto-compacts**. Each iteration starts fresh with deterministic allocation.

### 4. Human on the Loop

There are three modes of operation:

- **Human IN the loop** (bad): You make every decision, the LLM just executes
- **Human ON the loop** (good): You observe, notice patterns, steer when needed
- **AFK** (best for certain tasks): Let it run, check in periodically

From the transcripts: "Treat it like a fireplace - sit and watch, notice when it needs fuel."

### 5. Golden Windows

When the context is perfect and the LLM is performing optimally:

- **Save it**
- Note what made it successful
- Use it as a checkpoint for future iterations

This is critical for reproducible results and avoiding repeated mistakes.

## Architecture

### Outer Orchestrator + Inner Agents

```
┌──────────────────┐
│  Orchestrator    │  ← Decides which agent to call, manages loop
└────────┬─────────┘
         │
         ├─────────┬─────────┬──────────┐
         ▼         ▼         ▼          ▼
    ┌────────┐ ┌───────┐ ┌────────┐ ┌────────┐
    │ Spec   │ │ Coder │ │ Tester │ │Reviewer│
    │ Agent  │ │ Agent │ │ Agent  │ │ Agent  │
    └────────┘ └───────┘ └────────┘ └────────┘
         │         │         │          │
         └─────────┴─────────┴──────────┘
                   ▼
            Common Interface:
            - verify(context)
            - execute(context)
            - complete?(context)
```

Each agent:
- Has its own context window
- Reads from `your-project/agents/AGENT.md` for instructions
- Implements the common interface
- Is responsible for tool calling based on its instructions

### Project Structure

```
crayons/                              # Crayons system (this repo)
├── README.md                          # This file
└── lib/
    ├── crayons/
    │   ├── orchestrator.rb            # Main loop controller
    │   ├── agents/
    │   │   ├── base.rb                # Common interface
    │   │   ├── spec.rb                # Generates specs from requirements
    │   │   ├── coder.rb               # Implements code to pass specs
    │   │   └── ...
    │   ├── context/
    │   │   ├── allocator.rb           # Token-aware context management
    │   │   └── workspace.rb           # Persistent state
    │   └── tools/
    │       ├── bash.rb                # Command execution
    │       ├── files.rb               # File I/O
    │       └── git.rb                 # VCS operations
    └── ralph.rb                       # Entry point

your-project/                          # Your project (external to this repo)
├── ARCHITECTURE.md                    # Project-specific architecture
├── TESTING.md                         # Project-specific testing rules
└── agents/
    ├── SPEC.md                        # Spec generation instructions
    ├── MARGE.md                       # Marge instructions
    └── ...
```

## This Ruby Implementation's Approach

### Single Agent, No Parallelism (For Now)

Unlike Loom (which runs multiple weavers in parallel), this focuses on a single loop with multiple subagents. Parallelism can be added later once the sequential version is stable.

### Spec Generation is the Hard Part

The transcripts emphasize: **"One bad spec equals 10,000 lines of crap and junk"**

This system prioritizes:

1. **Spec Agent** → Converts requirements into test descriptions (quick, low token cost)
2. **Orchestrator validation** → Ensures specs cover requirements adequately
3. **Spec Agent (Phase 2)** → Implements full test suite
4. **Coder Agent** → Implements code to make specs green

The Coder Agent is easy - they just follow the contract. The Spec Agent does the real software engineering work.

### Agent-Specific Instructions

Each agent has its own instruction file:

```markdown
---
name: MARGE
description: An agent for writing or editing code
tools:
  - bash
  - files
---

You are a Coder Agent. Your job is to implement code that passes the specs.

## Verification Process

After editing ANY code, you MUST:

1. Run the verification command specified in TESTING.md
2. If verification passes: report success with specific metrics
3. If verification fails: extract ONLY the failing cases, identify root cause
4. NEVER output full test suite output - that wastes tokens

## Task completion

If, and only if, your work is complete return `<promise>COMPLETE</promise>`
```

The LLM is responsible for interpreting these instructions and calling tools appropriately.

## Why This Works

### Deterministic Allocation

Every iteration:
1. Pre-allocate project context (your-project/ARCHITECTURE.md, TESTING.md, agent instructions)
2. Allocate the current goal/objective
3. Allocate working context as needed
4. Never auto-compact - if context gets too large, reset

This means: every iteration is predictable and reproducible.

### Fail Fast, Iterate Often

- Specs are generated quickly (descriptions only, not implementations)
- Validation catches gaps early
- Each iteration is small and focused
- You can watch the loop, notice patterns, and steer

### Context Engineering

Treat the context window as a precious resource:

- Use concise language (tokens matter)
- Only include what's necessary
- Prefer code over explanations
- Compress similar operations

## Differences from Other Approaches

### vs Anthropic's Ralph Plugin

| Aspect | Anthropic Plugin | This Implementation |
|--------|------------------|---------------------|
| Compaction | Auto-compaction (lossy) | No auto-compaction |
| Context | Grows indefinitely | Resets each iteration |
| Determinism | Can lose specs/goals | Fully deterministic |
| Control | Promise-based completion | Explicit goal/objective |

### vs Cursor/Claude Code

| Aspect | Cursor | This Implementation |
|--------|--------|---------------------|
| Loop | Manual | Automated |
| Context | Human manages every step | Orchestrator manages |
| Specs | Often ad-hoc | First-class, generated by dedicated agent |

## Getting Started

1. Read this README for system design principles
2. Create your project directory with TESTING.md and ARCHITECTURE.md
3. Define agent instructions in `your-project/agents/`
4. Run the orchestrator with your requirements

The system will iterate through:
- Generate spec descriptions
- Validate specs cover requirements
- Implement full test suite
- Write code until all specs pass

## Key Insights from the Transcripts

1. **Never blame the model** - always be curious about why something happened
2. **Feel the failure domains** - run it, watch it break, engineer away those failures
3. **Treat software as clay** - malleable and reshapeable, not brittle
4. **Less is more** - minimal context for maximum performance
5. **Watch for patterns** - when running AFK, notice what works and what doesn't

## References

- Original Ralph Wiggum demonstrations by Geoffrey Huntley
- "An early preview of Loom" - infrastructure orchestrator of Ralph loops
- "Ralph Wiggum (and why Claude Code's implementation isn't it)" - Geoffrey Huntley & Dexter Horthy

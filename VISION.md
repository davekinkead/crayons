# Vision

Crayons is an experimental ralph-loop for autonomous software development via simple agents defined as markdown files.

It does this by providing a framework for gently nudging iterative agentic processes towards a larger goal.

## Key Concepts

### Tools

Tool use is what makes an agent an agent. Define them with a DSL and specify their behaviour in `#call`.

Tools ALWAYS return a string with a keyword. `SUCCESS: {brief message}` or `FAILURE: {detailed explanation}`.

### Agents

Define agents declaratively in markdown eg `agents/LISA.md` or `agents/APU.md`.

Crayons provides some default agents but will preference project agents.

### Default agents

Crayons comes with a few pre-built agents:

**RALPH** reads the vision document to see what has been done and what needs to be done. He bites off the smallest unit of work and creates a short PRD for it. He then spawns a BART to orchestrate the PRD and when BART finishes, he evalutes how the work has moved the vision forward, commits successful work to git, and updates the VISION document accordingly.

**BART** orchestrates a single PRD through a deterministic MARGE → APU → LISA cycle, tracking PRD status, and returning SUCCESS when all agents pass tests and rubocop.

**MARGE** implements PRD requirements using red-green TDD—writing specs first, then minimal code to make them pass—following Ruby conventions and verifying with rubocop and tests.

**APU** validates that specs adequately cover PRD requirements and follow testing standards—checking test fidelity, quality (behavior-focused naming, proper structure), assertion strategy (robust over brittle), and coverage (green and red paths)—without reading implementation code.

**LISA** validates that implementation code meets project quality standards and architectural requirements—checking code style, architecture compliance, error handling, code organization, dependencies, and documentation—without reading specs (APU handles that).

**WILLIE** is an explorer agent. Given a problem description, he finds all relevant files and provides clear sign posts for other agents including file names, paths, and key code snippets to grep for. Other agents can use WILLIE to get this info and pass it on down the agent chain to limit API use.

### Agents Are Just Tools

Agents and tools share a unified interface so that agents can use other agents like they use deterministic tools.

```ruby
module Crayons
  module Executable
    def name = raise NotImplementedError
    def description = raise NotImplementedError
    def parameters = {}
    def call(**kwargs) = raise NotImplementedError
  end
end
```

Create everything via a factory.

```ruby
Crayons::Tool.new(:bash).call("git log --grep=haiku")
Crayons::Tool.new(:lisa).call("Review the latest changes and ensure they comply with TESTING.md standards.")
```

Now agents can spawn other agents ;)

## Expect Failure

Agents are disposable and ephemeral. If they fail, it's okay to throw away their work and restart. They often get stuck in loops, so design them to fail early and quickly.

Every agent must return a SUCCESS or FAILURE message. They need should handle all internal errors so they always return a string

Agents should monitor their own performance and return a FAILURE when needed.

Agents should be able to be terminated by parent processes with `agent.die "You took too long"`.

## Keep 'Em Stupid

Each agent should have a single, focused responsibility. Simple agents are more predictable and easier to debug than complex multi-purpose agents.

## Context Is King

Agents have their own context. When spawning agents, each gets a fresh context to prevent information bleed between iterations.

Tools should return the minimal amount of information needed to do the job to prevent context pollution:
- SUCCESS messages should be short
- FAILURE messages should be detailed
- Large returns must be truncated with a warning
- Malloc deliberately. If the same tool is repeatedly called, only the latest is needed in message history
  - `read a ... read b` → keep both
  - `read a ... read a` → remove the first tool call from message history

## Performance Through Parallelisation

Design for concurrency.

Tools should enable bulk operations (e.g., `read` with multiple file arguments) to minimize round trips. Batch tool calls together for parallel execution when possible.

Crayons uses ruby threads via the `async` gem. Wrap all blocking operations in an `async do` block.

## Agents

An agent is an ephemeral loop with its own context using a common interface.

Agents are defined in `agents/*.md` with YAML frontmatter specifying name, description, and tools.

Current agents:

- **BART** - Orchestrator that coordinates work through a loop
- **MARGE** - Implements code using TDD workflow
- **LISA** - Evaluates specs and PRDs
- **APU** - Validates test quality and coverage
- **WILLIE** - Explorer agent that finds relevant files
- **HAIKU** - Generates haikus for testing

Run individual agents with `bin/agent --agent NAME --call "instructions"`

## Visibility

It's important to see agent processes as they run. This is realized via logging that can be streamed.

Logging follows a structured format:
- DEBUG: tool calls and responses in the format `[agent-id] [tool] CALL|RESPONSE {param|result}`
- INFO: agent lifecycle events showing start/complete with prompt/return message
- ERROR: maximum detail with no truncation limit

Non-ERROR log lines are truncated to 500 characters. Large payloads (like HTTP requests) are summarized with key fields instead of full JSON dumps.

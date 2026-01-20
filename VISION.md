# Vision

Crayons is a Ruby-based autonomous software development system that implements the Ralph Wiggum technique—human-on-the-loop agentic development at scale—through markdown-defined agents (Ralph, Bart, Marge, Apu, Lisa) that cycle through PRD implementation with deterministic context management, test-first development, and tool-based file operations, emphasizing minimal context allocation to keep LLMs in their "smart zone" for reliable, reproducible autonomous coding.

The goal is simple. Describe your product idea in a VISION document. Define task specific agent personas in your agent documents. Then release them and let them incrementally build your vision.

As work progresses, the user will also update the document in the **User Feedback** section. These are todo style user prompts that progressively steer the direction of CLANCY loops.  During his supervision, CLANCY might have questions for the user which he adds to **Agent Questions**. Over time the user answers these and CLANCY adapts the VISION accordingly.

The intent of this workflow is that agents are NEVER blocked. They follow their instructions the best they can and corrections are made as adjustments later. **The key requirement is that the system works at all times**. It is a permanent work in progress but ALWAYS WORKS.

## Agents

An agent is an ephemeral loop with their own context using a common interface.  You instantiate them, `#call` them with a prompt, and they get to work. They **always** return a SUCCESS or FAILURE message.

Agents are defined by their agents/PROMPT which describes their behaviour and tools. The most important tool is `spawn_agent` which spins up new agents in with their own context. This means that agents are also tools which can be chained together.

Important requirements are that:
- Agents are disposible and ephemeral. If they fail it is ok to throw away their work.
- Agents have their own context.
- Agents are blackboxes. Other agents wont know what they are doing internally.
- Agents use a consistent interface so they can be chained

**CLANCY** reads the vision document to see what has been done and what needs to be done. He bites off the smallest unit of work and creates a short PRD for it. He then spawns a BART to orchestrate the PRD and when BART finishes, he evalutes how the work has moved the vision forward, commits successful work to git, and updates the VISION document accordingly.

**BART** orchestrates a single PRD through a deterministic MARGE → APU → LISA cycle, tracking PRD status, and returning SUCCESS when all agents pass tests and rubocop.

**MARGE** implements PRD requirements using red-green TDD—writing specs first, then minimal code to make them pass—following Ruby conventions and verifying with rubocop and tests.

**APU** validates that specs adequately cover PRD requirements and follow testing standards—checking test fidelity, quality (behavior-focused naming, proper structure), assertion strategy (robust over brittle), and coverage (green and red paths)—without reading implementation code.

**LISA** validates that implementation code meets project quality standards and architectural requirements—checking code style, architecture compliance, error handling, code organization, dependencies, and documentation—without reading specs (APU handles that).

## Agent Context

Agents are disposable and ephemeral. They often get stuck in loops so it is ok to have them fail early and then just re-start them. The system needs to be designed around the inevitablility of agent failure.

But agents still need to be designed so they ALWAYS return a SUCCESS or FAILURE message. The need internal error handling for this which will allow calling agents to know how to respond.

## Visibility

It is very important for the user to see agent processes as they run. This will initially be realised via logging that can be streamed by an external service.

Logging follows a structured format:
- DEBUG: tool calls and responses in the format `[agent-id] [tool] CALL|RESPONSE {param|result}`
- INFO: agent lifecycle events showing start/complete with prompt/return message
- ERROR: maximum detail with no truncation limit

Non-ERROR log lines are truncated to 500 characters. Large payloads (like HTTP requests) should be summarized with key fields instead of full JSON dumps.

## Concurrency

Performance will be enhanced through the use of `async` Ruby so that calls to LLMs and agent completions do not block the process. HTTP clients will leverage Ruby's async capabilities with fiber-based concurrency, maintaining a synchronous interface for callers while enabling non-blocking I/O operations under the hood to improve throughput when multiple agents run concurrently.

HTTP clients must handle errors gracefully by rescuing from StandardError and raising appropriate NetworkError exceptions with meaningful context, avoiding direct exposure of library-specific error objects.

Concurrent agents should be possible throught the use of git worktrees. This means that agents need to be instantiated with a required 'workdir' param, this value is injected into ALL took execution. For security purposes, tool calls with argument paths not containing the workdir MUST be rejected with an appropriate message.

CLANCY will need to create git worktrees for BART. The worktree names should reflect the RPD name and the `workdir` agent param.

## Git

Concurrent agents require a specific git workflow involving git worktrees.

CLANCY works from `main` and should be created with `dir: "./"`.  CLANCY creates git worktrees that match the PRD file name. He can then spawn BART with the worktree as the dir param.

BART should be working in the context of a worktree. The allows BART to commit frequently as a way of persisting memory between agent processes (agents are ephemeral and have no memory). All tooling must therefore enforce `dir` compliance.

Bart can commit all code on success or just udpates to the PRD on failure. This way BART can keep a record of failures until he returns SUCCESS

CLANCY should decide what to merge based on BART's success or failure. If BART succeeds, CLANCY should squash-merge the worktree back into main as a single commit with a comprehensive message. If BART fails, CLANCY can commit document updates for memory and just spawn another BART.


---

## User Feedback

- [x] URGENT: Somewhere a long the way the santization of the bash tool was removed. Forbid dangerous actions that agents with full access should be banned from.
- [x] BUG: NEVER log during specs - if tests pass, they should only show the test summary. See http_spec.rb
- [x] Implement async. use the async gem and httpx plugin. Wrap agent instantiation in spawn_agent tool as this is where blocking starts.
- [x] Better HTTPX error management. We need to get the actual error from ErrorResponse and throw that, not `undefined method 'status' for an instance of HTTPX::ErrorResponse`
- [x] Runtime error still occurring. See `[2026-01-20 17:17:38] [ERROR] [AGENT:BART:488]` in logs.
    ```
    Crayons::Clients::HTTP::NetworkError: Network error: undefined method 'status' for an instance of HTTPX::ErrorResponse
    /Users/davekinkead/Projects/crayons/lib/crayons/clients/http.rb:83:in 'Crayons::Clients::HTTP#handle_response'
    ```
    The implementation needs to properly check for HTTPX::ErrorResponse type before attempting to call `.status` on the response object. The error indicates that line 83 is still trying to call `.status` on an HTTPX::ErrorResponse object without proper type checking.
    It might be a very good idea to create a small wrapper for the response that normalizes the different HTTPX::Response and HTTPX::ErrorResponse objects.
- [ ] Add a `dir` param to agent.rb. `Crayons::Agent.new(:coder, fir: "/path/to/worktree")`. For now, dir should always be './'.  This is a required param with no defaults. Ensure tool use limits all actions to relative paths based on this. Tools should give error feedback that the caller is in `dir`. This will make git worktree (to do later) easier to use.
- [ ] CLANCY is not commiting all the changed files in the final git commit. Ensure the prompt refects the require to commit work on SUCCESS.
- [ ] Dont create unit tests for processes. Unit tests should match the class they are testing


## Agent Questions


## Progress

- Implemented basic Agent class loading personas from markdown files with YAML frontmatter
- Created HTTP client for LLM API integration with async HTTPX support
- Built Tool DSL for defining tool interfaces with description and parameters
- Implemented BashTool for command execution and file operations
- Created file tools: ReadFileTool, WriteFileTool, EditFileTool for code manipulation
- Added Message class for conversation history and role tracking
- Implemented Agent#call loop with tool execution and iteration management
- Created grep and glob tools for codebase search and file discovery
- Added error handling with standardized SUCCESS/FAILURE return format
- Implemented Ruby Logger integration for agent execution tracking
- Created SpawnAgentTool for launching fresh agent contexts from agents
- Defined BART orchestrator agent with PRD completion loop
- Implemented MARGE agent with TDD workflow (specs first, then code)
- Created APU agent for validating test coverage and quality standards
- Implemented LISA agent for code quality and architecture compliance
- Completed AGENTS.md with agent creation and usage guide
- Added Rubocop to enfore styles
- Verified full CLANCY → BART → MARGE → APU → LISA workflow with HelloWorld class implementation
- Fixed HTTPX ErrorResponse handling to rescue from StandardError and raise NetworkError
- Updated logging format: tool CALL/RESPONSE format, HTTP payload summary, 500-char truncation for non-ERROR logs
- Fixed HTTPX ErrorResponse type checking before accessing status method to prevent 'undefined method' errors
- Added comprehensive error message extraction for ErrorResponse objects with multiple fallback strategies
- Implemented async/await support using async gem with fiber-based concurrency in HTTP client and SpawnAgentTool
- Maintained synchronous interface for callers while enabling non-blocking I/O operations internally
- Fixed Async logging during specs by handling exceptions inside Async blocks to prevent stderr warnings
- Added command sanitization to BashTool to forbid dangerous commands (rm, rmdir, dd, mkfs, kill, sudo, chmod, chown, apt-get, yum, brew, mv, cp) while allowing safe development commands (echo, ls, cat, grep, find, git, ruby, rspec)

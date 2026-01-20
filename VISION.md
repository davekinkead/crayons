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

## Concurrency

Performance will be enhanced through the use of `async` Ruby so that calls to LLMs and agent completions do not block the process.

Concurrent agents should be possible throught the use of git worktrees. This means that agents need to be instantiated with a required 'workdir' param, this value is injected into ALL took execution. For security purposes, tool calls with argument paths not containing the workdir MUST be rejected with an appropriate message.

CLANCY will need to create git worktrees for BART. The worktree names should reflect the RPD name and the `workdir` agent param.

## Git

CLANCY needs to create git worktrees when he creates PRD. When he spawns BART, he needs to provide worktree and PRD information (the names should match)

BART should be working in the context of a worktree. The allows BART to commit frequently as a way of persisting memory between agent processes (agents are ephemeral and have no memory). Bart can commit code on success or just udpates to the PRD on failure.

CLANCY should decide what to merge based on BART's success or failure. If BART succeeds, CLANCY should squash-merge the worktree back into main as a single commit with a comprehensive message. If BART fails, CLANCY can commit document updates for memory and just spawn another BART.

---

## User Feedback

- [ ] Agents are getting stuck in run away tool use. The current max-iterations counter is for conversations, not internal message count. Let's start with a 10 message limit and go from there.
- [ ] The system is running slow. Focus on `async` first.
- [x] BUG: HTTPX ErrorResponse object doesn't have a .status method. Update `handle_response` rescue from any StandardError and raise a NetworkError
- [ ] Better HTTPX error management. We need to get the actual error from ErrorResponse and throw that, not `undefined method 'status' for an instance of HTTPX::ErrorResponse`
- [x] Logging updates ...
  - [x] DEBUG: tool calls and responses like `[agent-id] [tool] CALL|RESPONSE {param|result}`
  - [x] INFO: show agent start/complete with prompt/return message
  - [x] ERROR: give as much detail as possible. no limit.
  - [x] No more message json - swap `@logger.debug("HTTP", "Payload: #{payload.to_json}...")` for `[DEBUG] [HTTP] Payload: model=GLM-4.7, messages=3, tools=5`
  - [x] truncate all log lines to 500 chars
  - [x] Everything else stays as-is.

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

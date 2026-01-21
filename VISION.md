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

**WILLIE** is an explorer agent. Given a problem description, he finds all relevant files and provides clear sign posts for other agents including file names, paths, and key code snippets to grep for. Other agents can use WILLIE to get this info and pass it on down the agent chain to limit API use.

## Tools

Agents have access to tools to do their job. The tool access is defined in their markdown file.

Tools should enable bulk calling eg `read_file` with mutliple file arguments.

Tools should return the minumal amount of information to do the job to prevent context polution.
- Large returns must be truncated with a warning.
- If the same tool is repeatedly called, only the latest is needed
  - `read_file a ... read_file b` => keep both
  - `read_file a ... read_file a` => remove the first tool call from the message history.

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

In the initial stages of the project, there will be no concurrency. It is acceptable for agents to block each other.

## Git

All agents will work off main. CLANCY is soley reponsible for git commits when BART is successfull.

---

## User Feedback

- [x] Remove async logic - it is causing network issues that we will fix later.
- [x] Create WILLIE the explorer agent
- [x] Readfile tool should accept mutliple file arguments
- [ ] Add a user agent to the http client and set it to User-Agent: opencode/{VERSION}
- [ ] Create a verification tool to run `rspec` and `rubocop -A` - less thinking for agents.
- [ ] Remove earlier tool calls from message history if they are duplicates
- [x] Add a `dir` param to agent.rb. `Crayons::Agent.new(:coder, fir: "/path/to/worktree")`. For now, dir should always be './'.  This is a required param with no defaults. Ensure tool use limits all actions to relative paths based on this. Tools should give error feedback that the caller is in `dir`. This will make git worktree (to do later) easier to use.


## Agent Questions


## Progress

- Implemented basic Agent class loading personas from markdown files with YAML frontmatter
- Created HTTP client for LLM API integration with synchronous HTTPX
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
- Removed async/await logic to resolve network issues; HTTP client and SpawnAgentTool now synchronous
- Added command sanitization to BashTool to forbid dangerous commands (rm, rmdir, dd, mkfs, kill, sudo, chmod, chown, apt-get, yum, brew, mv, cp) while allowing safe development commands (echo, ls, cat, grep, find, git, ruby, rspec)
- Extracted command sanitization logic into Crayons::CommandSanitizer module for reuse across bash, grep, and glob tools
- Refined sanitization rules: now allow cp, mv, brew, wget, curl; allow rm without recursive flags but block rm -r, -rf, etc.
- Created WILLIE explorer agent with minimal output format (file paths + one-line relevance) and ExploreTool wrapper with integration test
- Updated ReadFileTool to accept multiple file arguments (string or array) with backwards compatibility; added comprehensive test suite with 30 tests covering single/multiple files, error scenarios, and edge cases

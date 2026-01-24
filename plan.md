# Crayons Tool System Plan

## Overview
Tools are the foundation of Crayons - wrappers that agents can call deterministically.

## Status: ✅ Core System Complete

## Completed Components

### 1. Tool Interface (`lib/tool.rb`)
✅ Abstract base class defining the tool contract

### 2. Tool Factory (`lib/tools.rb`)
✅ Factory pattern for creating tool instances
```ruby
Crayons::Tools.new(:haiku)     # Returns HaikuTool instance
Crayons::Tools.new(:bash)      # Returns BashTool instance
Crayons::Tools.new(:unknown)   # Raises ToolNotFoundError
Crayons::Tools.new(:marge)     # Returns AgentTool (agent as tool)
```

### 3. Agent System (`lib/agent.rb`)
✅ Agent class for tool calling orchestration
✅ HTTP client with async-http (`lib/clients/http.rb`)
✅ Zai API integration (`lib/clients/zai.rb`)
✅ Custom logger with unique IDs (`lib/logger.rb`)
✅ Message history management (`lib/message.rb`)
✅ CLI interface with agent-as-tool capability

### 4. Built-in Tools
✅ Haiku Tool (`tools/haiku.rb`) - Generate haikus for testing
✅ Bash Tool (`tools/bash.rb`) - Execute shell commands with timeout
✅ Read File Tool (`tools/read_file.rb`) - Read file contents
✅ Write File Tool (`tools/write_file.rb`) - Write content to files
✅ Find Tool (`tools/find.rb`) - Find files by glob pattern
✅ Grep Tool (`tools/grep.rb`) - Search file contents with regex
✅ Agent Tool (`tools/agent_tool.rb`) - Call agents as tools

## Directory Structure

```
lib/
├── agent.rb              # Agent class for tool orchestration
├── tool.rb               # Base class
├── tools.rb              # Factory module
├── errors.rb             # Custom errors
├── logger.rb             # Custom logging with unique IDs
├── message.rb            # Message handling
├── utils.rb              # Shared utilities
├── clients/
│   ├── base.rb           # Base client class
│   ├── http.rb           # HTTP client with async-http
│   └── zai.rb            # Zai API integration
└── tools/
    ├── haiku.rb
    ├── bash.rb
    ├── read_file.rb
    ├── write_file.rb
    ├── find.rb
    ├── grep.rb
    └── agent_tool.rb     # Agent-as-tool wrapper

agents/
├── MARGE.md              # Management agent
└── TEST.md               # Test agent

bin/
└── verify                # Run tests and linting
```

---

## Remaining Work

### 1. Batch Tool with Async Execution ⏳
- Implement `tools/batch.rb` to execute multiple tools concurrently
- Use Async gem for fiber-based parallel execution
- Maintain standard tool interface
- Return aggregated results with success/failure status per tool
- Add comprehensive error handling for partial failures

### 2. Workdir Parameter Support ⏳
- Update Tool base class to accept `workdir` parameter
- Enforce workdir compliance in all tools (bash, read_file, write_file, find, grep)
- Reject tool calls with paths outside the workdir
- Required for git worktree-based concurrent agent execution

### 3. Context Management ⏳
- Implement token counting and message truncation
- Add context compaction with sliding window pruning
- Create AI-powered summarization for overflow scenarios
- Protect critical messages from pruning (last 40k tokens)
- Track and log token usage

### 4. Enhanced Error Handling ⏳
- Implement retry logic with exponential backoff
- Add rate limiting middleware
- Improve timeout handling with configuration
- Better error messages and recovery suggestions

---

## Key Design Decisions

- **Factory pattern**: Clean instantiation via `Crayons::Tools.new(:name)`
- **Agent-as-tool**: Agents can be called as tools via AgentTool wrapper
- **Unique IDs**: Every agent instance gets unique ID for logging (name-object_id)
- **Test-first**: Every component has RSpec tests before implementation
- **Explicit errors**: `ToolNotFoundError` for unknown tools
- **Immutable context**: Tools receive context but never mutate it
- **Custom logger**: Unique IDs per agent instance for traceable logs

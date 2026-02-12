# Crayons Tool System Plan

## Overview
Tools are the foundation of Crayons - wrappers that agents can call deterministically.

## Status: ✅ Core System Complete + Multi-Agent Orchestration

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
    ├── batch.rb          # Concurrent tool execution
    └── agent.rb          # Agent-as-tool wrapper

agents/
├── RALPH.md              # Orchestration agent
├── MARGE.md              # Implementation agent
├── LISA.md               # Code review agent
├── MILHOUSE.md           # Test review agent
└── TEST.md               # Agent for test purposes

docs/
├── architecture.md       # SOLID principles and design patterns
├── code-quality.md       # Code quality standards
└── testing.md            # Testing standards and structure

bin/
└── verify                # Run tests and linting
```

---

## Remaining Work

### 1. Workdir Parameter Support ❌ NOT IMPLEMENTED
- All tools need to accept a `dir` parameter (default "./") on init that constrains their behavior
- Use a util class to enforce dir logic - should return simple things like true/false or the path
-
- Enforce workdir compliance in all tools execpt bash
- Reject tool calls with paths outside the workdir
- Required for git worktree-based concurrent agent execution (noted as "not relevant for implementation")

### 2. Context Management ⏳
- Prune repeated tool calls. Only the latest tool-arg combo should remain
  - eg `tool arg-a ... tool arg-b` => both remain
  - eg `tool arg-a ... tool arg-a` => only keep last

### 3. Enhanced Error Handling ⏳
- Implement retry logic with exponential backoff
- Add rate limiting middleware
- Improve timeout handling with configuration
- Better error messages and recovery suggestions

---

## Key Design Decisions

- **Factory pattern**: Clean instantiation via `Crayons::Tools.new(:name)`
- **Agent-as-tool**: Agents can be called as tools via AgentTool wrapper
- **Multi-agent orchestration**: RALPH coordinates MARGE (implementation), LISA (code review), MILHOUSE (test review)
- **Async parallel execution**: Batch tool and agent tool calls execute concurrently using Async gem
- **Unique IDs**: Every agent instance gets unique ID for logging (name-object_id)
- **Test-first**: Every component has RSpec tests before implementation
- **Explicit errors**: `ToolNotFoundError` for unknown tools
- **Immutable context**: Tools receive context but never mutate it
- **Custom logger**: Unique IDs per agent instance for traceable logs
- **SOLID principles**: Enforced through RALPH orchestration and LISA code review

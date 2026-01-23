# Crayons Tool System Plan

## Overview
Tools are the foundation of Crayons - wrappers that agents can call deterministically.

## Core Components

### 1. Tool Interface (`lib/tool.rb`)
Abstract base class defining the tool contract:

```ruby
class Crayons::Tool
  - name: String
  - description: String
  - params: [{ name: string, description: string, required: bool}]
  - call(*arg, **kwargs): Result
end
```

### 2. Tool Factory (`lib/tools.rb`)
Factory pattern for creating tool instances:

```ruby
Crayons::Tools.new(:haiku)     # Returns HaikuTool instance
Crayons::Tools.new(:bash)      # Returns BashTool instance
Crayons::Tools.new(:unknown)   # Raises ToolNotFoundError
```

Tools all have the same input ...

```ruby
Crayons::Tools.create(:haiku).call("write me a poem about hyperactive squirrels with kitchen knives")
```

And output ..

```ruby
 { success: true, result: "There once was a squirrel ...." }
```


## Directory Structure

```
lib/
├── tool.rb           # Base class
├── tools.rb          # Factory pattern
├── errors.rb         # Custom errors
└── tools/
    ├── haiku.rb
    ├── bash.rb
    ├── read_file.rb
    ├── write_file.rb
    ├── find.rb       # Find files by glob pattern
    └── grep.rb       # Search file contents with regex
```

## Built-in Tools

### 1. Haiku Tool (`tools/haiku.rb`)
- Generate a haiku
- No parameters required
- Simple implementation for HAIKU agent
- For testing purposes only

### 2. Bash Tool (`tools/bash.rb`)
- Execute shell commands
- Parameters: command (required), timeout (optional)
- Capture stdout/stderr/exit status

### 3. Read File Tool (`tools/read_file.rb`)
- Read file contents
- Parameters: filepath (required)
- Return file contents or error

### 4. Write File Tool (`tools/write_file.rb`)
- Write content to file
- Parameters: filepath (required), content (required)
- Create or overwrite file

### 5. Find Tool (`tools/find.rb`)
- Find files matching a glob pattern
- Parameters: pattern (required), path (optional)
- Return matching file paths

### 6. Grep Tool (`tools/grep.rb`)
- Search file contents using regex patterns
- Parameters: pattern (required), path (optional), include (optional)
- Return matching lines with file paths

## Key Design Decisions

- **Factory pattern**: Clean instantiation via `Crayons::Tools.new(:name)`
- **No registry**: Simpler, more explicit tool creation
- **Async execution**: All batch operations use Async gem for concurrency
- **Immutable context**: Tools receive context but never mutate it
- **Test-first**: Every component has RSpec tests before implementation
- **Explicit errors**: `ToolNotFoundError` for unknown tools

---

## Next Steps

### 1. Batch Tool with Async Execution
- Implement `tools/batch.rb` to execute multiple tools concurrently
- Use Async gem for fiber-based parallel execution
- Maintain standard tool interface: `batch(tools: [{name: :haiku, input: nil}, ...])`
- Return aggregated results with success/failure status per tool
- Add comprehensive error handling for partial failures

### 2. Workdir Parameter Support
- Update Tool base class to accept `workdir` parameter
- Enforce workdir compliance in all tools (bash, read_file, write_file, find, grep)
- Reject tool calls with paths outside the workdir
- Required for git worktree-based concurrent agent execution

### 3. Agent System
- Implement agent base class in `lib/agent.rb`
- Create LLM client (`lib/client/http.rb`) with async-http
- Add agent executor/loop with iteration limits
- Support agent configuration from markdown files (`agents/` directory)
- Integrate batch tool for parallel tool execution

### 4. Context Management
- Implement token counting and message truncation
- Add context compaction with sliding window pruning
- Create AI-powered summarization for overflow scenarios
- Protect critical messages from pruning (last 40k tokens)
- Track and log token usage

### 5. Enhanced Error Handling
- HTTP client: Handle HTTPX::ErrorResponse properly
- Implement retry logic with exponential backoff
- Add rate limiting middleware
- Improve timeout handling with configuration
- Better error messages and recovery suggestions

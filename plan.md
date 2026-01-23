# Crayons Tool System Plan

## Overview
Tools are the foundation of Crayons - wrappers that agents can call deterministically.

## Core Components

### 1. Tool Interface (`lib/crayons/tools/tool.rb`)
Abstract base class defining the tool contract:

```ruby
class Crayons::Tool
  - name: String
  - description: String
  - params: [{ name: string, description: string, required: bool}]
  - call(*arg, **kwargs): Result
end
```

### 2. Tool Factory (`lib/crayons/tools/tool_factory.rb`)
Factory pattern for creating tool instances:

```ruby
Crayons::Tool.new(:haiku)     # Returns HaikuTool instance
Crayons::Tool.new(:bash)      # Returns BashTool instance
Crayons::Tool.new(:unknown)   # Raises ToolNotFoundError
```

Tools all have the same input ...

```ruby
Crayons::Tool.new(:haiku).call("write me a poem about hyperactive squirrels with kitchen knives")
```

And output ..

```ruby
 { success: true, result: "There once was a squirrel ...." }
```


## Directory Structure

```
lib/crayons/tools/
├── tool.rb           # Base class
├── tool_factory.rb   # Factory pattern
└── built_in/
    ├── haiku.rb
    ├── bash.rb
    ├── read_file.rb
    ├── write_file.rb
    └── search.rb
```

## Built-in Tools

### 1. Haiku Tool (`built_in/haiku.rb`)
- Generate a haiku
- No parameters required
- Simple implementation for HAIKU agent
- For testing purposes only

### 2. Bash Tool (`built_in/bash.rb`)
- Execute shell commands
- Parameters: command (required), timeout (optional)
- Capture stdout/stderr/exit status

### 3. Read File Tool (`built_in/read_file.rb`)
- Read file contents
- Parameters: filepath (required)
- Return file contents or error

### 4. Write File Tool (`built_in/write_file.rb`)
- Write content to file
- Parameters: filepath (required), content (required)
- Create or overwrite file

### 5. Search Tool (`built_in/search.rb`)
- Search file contents using ripgrep
- Parameters: pattern (required), path (optional)
- Return matching lines and file paths

## Key Design Decisions

- **Factory pattern**: Clean instantiation via `Crayons::Tool.new(:name)`
- **No registry**: Simpler, more explicit tool creation
- **Async execution**: All batch operations use Async gem for concurrency
- **Immutable context**: Tools receive context but never mutate it
- **Test-first**: Every component has RSpec tests before implementation
- **Explicit errors**: `ToolNotFoundError` for unknown tools

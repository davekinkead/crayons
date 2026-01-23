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
    └── search.rb
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

### 5. Search Tool (`tools/search.rb`)
- Search file contents using ripgrep
- Parameters: pattern (required), path (optional)
- Return matching lines and file paths

## Key Design Decisions

- **Factory pattern**: Clean instantiation via `Crayons::Tools.new(:name)`
- **No registry**: Simpler, more explicit tool creation
- **Async execution**: All batch operations use Async gem for concurrency
- **Immutable context**: Tools receive context but never mutate it
- **Test-first**: Every component has RSpec tests before implementation
- **Explicit errors**: `ToolNotFoundError` for unknown tools

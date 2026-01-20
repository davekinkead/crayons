# Architecture of Crayons

Crayons is a Ruby-based autonomous software development system that follows the Ralph Wiggum technique.

## Core Components

### Agents

`Agents` use a single agent.rb file to instantiate personas based on markdown files (see `agents/CODER.md`).
- load personas from markdown
- declare `Tool` use in frontmatter
- have their own context
- connect to LLM services via a `Client`

```
agent = Agent.new :coder
response = agent.call "instructions"
```

### Clients

`Clients` manage the LLM API infrastructure. They are simple extentions of RubyLLM

```
azure_client = RubyLLM.context do |config|
  config.openai_api_key = ENV['AZURE_KEY']
  config.openai_api_base = "https://azure.openai.azure.com"
  config.request_timeout = 180
end
```


### Tools

Tools are defined as RubyLLM::Tool subclasses with a DSL for description and parameters.

```ruby
module Crayons
  class ReadFileTool < RubyLLM::Tool
    description "Read the contents of a file"

    params do
      string :file_path, description: "The absolute path to the file to read"
    end

    def execute(file_path:)
      content = File.read(file_path)
      { content: content, file_path: file_path, success: true }
    rescue => e
      { error: e.message, success: false }
    end
  end
end
```

Tools are registered in `Crayons::Tools`:
```ruby
Crayons::Tools.register(:read_file, Crayons::ReadFileTool)
```

Available built-in tools:
- `bash` - Execute bash commands
- `read_file` - Read file contents
- `write_file` - Write new files
- `edit_file` - Edit existing files
- `grep` - Search file contents
- `glob` - Find files by pattern
- `haiku` - Generate haikus (example tool)

## Directory Structure

```
crayons/
├── lib/crayons/
│   ├── agent.rb           # Agent class loads personas from markdown
│   ├── client.rb          # Client factory for LLM backends
│   ├── clients/
│   │   └── zai.rb         # Zai client implementation
│   ├── tools.rb           # Tool registry
│   └── tools/             # Tool implementations
│       ├── bash.rb
│       ├── read_file.rb
│       ├── write_file.rb
│       ├── edit_file.rb
│       ├── grep.rb
│       ├── glob.rb
│       └── haiku.rb
├── agents/                # Agent persona definitions
│   ├── CODER.md
│   └── HAIKU.md
└── spec/                  # Test suite
```

## Configuration

Clients are configured via environment variables:

- `ZAI_API_KEY` - API key for Zai (falls back to `OPENAI_API_KEY`)
- `OPENAI_BASE_URL` - Base URL for OpenAI-compatible API
- `OPENAI_MODEL` - Model to use (optional)
- `CRAYONS_CLIENT` - Client implementation to use (defaults to `:zai`)

## Client Factory Pattern

The `Crayons::Client.new` factory selects the client implementation based on the `CRAYONS_CLIENT` environment variable, defaulting to `Zai`. New clients can be added by:

1. Creating `lib/crayons/clients/your_client.rb` inheriting from `Crayons::Clients::Base`
2. Setting `ENV['CRAYONS_CLIENT'] = 'your_client'`

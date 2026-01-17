# Son of Ralph

A Ruby-based autonomous software development system using the Ralph Wiggum technique.

## Overview

Son of Ralph enables autonomous software development through simple agents defined as markdown files. Each agent has its own persona, instructions, and tools, connecting to LLM services via RubyLLM.

Inspired by [Geoffrey Huntley](https://ghuntley.com/ralph/).

## Features

- Simple agent definitions with YAML frontmatter
- Tool DSL for file operations, bash commands, and more
- Deterministic context management
- Test-first development with RSpec

## Installation

```bash
git clone https://github.com/yourusername/son-of-ralph.git
cd son-of-ralph
bundle install
```

## Configuration

Set required environment variables:

```bash
export ZAI_API_KEY="your-api-key"  # or OPENAI_API_KEY
export OPENAI_BASE_URL="https://your-api-endpoint.com"  # optional
export OPENAI_MODEL="your-model"  # optional
```

## Usage

```ruby
require 'ralph'

agent = Ralph::Agent.new :coder
response = agent.call "Implement a function to reverse a string"
puts response
```

## Available Agents

- **Coder** - Implements code to pass specs
- **Haiku** - Generates haikus (for testing)

## Creating Agents

Define agents in `agents/AGENT.md`:

```yaml
---
name: MY_AGENT
description: Brief description
tools:
  - bash
  - read_file
---

You are an agent. Your instructions go here.

## Task completion

Return `<promise>COMPLETE</promise>` when finished.
```

## Testing

```bash
bundle exec rspec
```

## Documentation

- [AGENTS.md](AGENTS.md) - Quick start guide for agents
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and components
- [TESTING.md](TESTING.md) - Testing guidelines and structure

## License

MIT

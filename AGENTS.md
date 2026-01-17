# Son of Ralph

Son of Ralph is a project for autonymous agentic software development that follows the Ralph Wiggum process.

It uses simple agents defined in markdown files that connect to LLM services via RubyLLM. Each agent has its own persona, instructions, and tools.

The system consists of three core components: Agents (personas from markdown), Clients (LLM API connections), and Tools (RubyLLM DSL utilities).

**WARNING**: This is experimental and will change without warning. For learning purposes only.

## Tech Stack

- **Ruby** ~3.0 - Core language
- **RubyLLM** - LLM client library and tool DSL
- **RSpec** - Test framework
- **YAML** - Agent frontmatter parsing

## Detailed Documents

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture: components, tools, and configuration
- [TESTING.md](TESTING.md) - Testing guidelines: test structure and verification process
- [BACKGROUND.md](BACKGROUND.md) - Project background: Ralph Wiggum technique and principles
- [README.md](README.md) - Project Overview

Always run `bundle exec rspec` after making changes and ensure all tests pass.

## Ralph Agents

Agents are defined in `agents/` as markdown files with YAML frontmatter.

```ruby
agent = Ralph::Agent.new :coder
response = agent.call "your instructions here"
```

```
agents/
├── CODER.md (for writing code)
└── HAIKU.md (for internal testing)
```

## Agent Format

```yaml
---
name: AGENT_NAME
description: Brief description
tools:
  - bash
  - read_file
---

You are an agent. Your instructions go here.

## Task completion

Return `<promise>COMPLETE</promise>` when finished.
```

## Available Agents

- [Coder](agents/CODER.md) - Implement code to pass specs
- [Haiku](agents/HAIKU.md) - Generate haikus

Copyright 2026 Dave Kinkead

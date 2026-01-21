# Crayons

Autonomous agent development system. Agents defined in markdown files connect to LLM services and use tools to accomplish tasks.

## Key Documentation

- **ARCHITECTURE.md** - System architecture, components, configuration
- **TESTING.md** - Testing guidelines and TDD process
- **BACKGROUND.md** - Project background and Ralph Wiggum technique
- **README.md** - Project overview

## Verification

Always run `bundle exec rspec` after changes. Ensure all tests pass.

## How Agents Work

Agents are defined in `agents/*.md` with YAML frontmatter specifying name, description, and tools.

```ruby
agent = Crayons::Agent.new :coder
response = agent.call "your instructions"
```

## Available Agents

- [Bart](agents/BART.md) - Orchestrator
- [Marge](agents/MARGE.md) - Implement code to pass specs
- [Lisa](agents/LISA.md) - Evaluates specs & PRDs
- [Apu](agents/APU.md) - Validates test quality and coverage
- [Haiku](agents/HAIKU.md) - Generate haikus for testing
- [Willie](agents/WILLIE.md) - Explorer agent that finds relevant files and provides signposts

You can run individual agents with the script `bin/agent --agent LISA --call "instructions for LISA"`

## Behavioral Guidelines

1. **ALWAYS Confirm before editing**: Present intended changes and wait for user approval
2. **Sprint on YOLO**: If the user says YOLO keep going until you are told to stop
3. **Start with summaries**: Provide high-level overview first, elaborate on request
4. **Ask when unclear**: Seek clarification for ambiguous or complex requests
5. **Think before acting**: Plan and reflect before implementing changes
6. **Verify work**: Test and confirm changes work correctly
7. **Match code style**: Follow existing patterns and conventions
8. **Stay focused**: Address the specific request without adding extras

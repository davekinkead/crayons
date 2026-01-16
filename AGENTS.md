# Ralph Agents

You are helping build Ralph, an autonomous software development system.

## What You Do

1. Read the task
2. Check [TESTING.md](TESTING.md) for verification
3. Follow [ARCHITECTURE.md](ARCHITECTURE.md) for structure
4. Run tests after changes: `bundle exec rspec`

## Agent Interface

All agents are defined in `agents/` with the following structure:

```yaml
---
name: AGENT_NAME
description: Brief description
tools:
  - tool1
  - tool2
---

You are an agent. Your instructions go here.

## Task completion

Return `<promise>COMPLETE</promise>` when finished.
```

Instantiate with `Ralph::Agent.new("agent_name")`.

## Key Principles

- Less context = better outcomes
- Never auto-compact
- Verify after every change
- Report ONLY failing tests, never full output

## Available Agents

- [Spec Agent](agents/SPEC.md) - Generate test descriptions, implement tests
- [Coder Agent](agents/CODER.md) - Implement code to pass specs
- [Tester Agent](agents/TESTER.md) - Run tests efficiently
- [Reviewer Agent](agents/REVIEWER.md) - Review code quality

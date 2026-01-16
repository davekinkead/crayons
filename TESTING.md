# Testing Ralph

This document describes how to test the Ralph system itself.

## Test Structure

Tests are located in `spec/` directory.

## Running Tests

```bash
bundle exec rspec
```

## Test Categories

### Unit Tests
- Individual agent behavior
- Context management
- Tool execution

### Integration Tests
- Agent orchestration
- End-to-end workflows
- Context window management

### LLM Integration Tests (Optional)
- Requires API keys
- Tests actual LLM agent behavior
- Marked with `:llm_integration` tag

## Test Requirements

- All tests must pass before commits
- No tests should depend on external state
- Mock LLM calls unless testing actual integration

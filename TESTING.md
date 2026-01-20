# Testing Crayons

This document describes how to test the Crayons system itself.

## Test Structure

Tests are located in `spec/` directory.

## Testing Process

1. Start by reading the individual PRD or instructions you have been given
2. Write acceptance criterica using empty `it "does something"` statements
3. Stop and reflect ...
  - do these specs accurately reflect what's required by the PRD?
  - am I testing the right things - outputs & behaviours, not implementation
  - am I testing the right areas - unit tests for isolated behaviour
4. Update your tests if needed
5. Implement ONE TEST ONLY so that if fails
6. Implement the code so the test passes
7. Repeat until all tests are implemented and passing

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
- Requires API keys
- Maunually run
- Tests actual LLM agent behavior
- do not use the `_spec.rb` suffix

## Test Requirements

- All tests must pass before commits
- No tests should depend on external state
- Mock LLM calls unless testing actual integration

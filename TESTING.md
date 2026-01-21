# Testing Crayons

## Test Structure

Tests are located in `spec/` directory.

FIX: show dir structure with explaination

## Testing Driven Development

When writing code, follow these TDD principles:

1. Understand the requirements
2. Describe the BEHAVIOUR of the requirements in clear statements like `it "returns nil when user is not found"`
3. Implement ONE TEST ONLY so that if fails
4. Implement the code so the test passes
5. Repeat until all tests are implemented and passing

## Running Tests

Use rspec to run specify specs

```bash
bundle exec rspec path_to_spec.rb
```

Or run all specs and lints at once with:

```bash
bin/verify
```

## Test Quality

Follow these requirements closely:

### All Tests
- only test public methods
- test behaviour not implementation
- keep tests independent - don't have dependencies between tests

### Unit Tests
- Test individual classes
- Mock any dependencies

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

## Test Limits

- Agents rely on external LLM APIs.
- Automated tests of behaviour that relies on LLMs is impossible.

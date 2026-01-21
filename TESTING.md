# Testing Crayons

## Test Structure

Tests are located in `spec/` directory:

```
spec/
├── unit/          # Full isolated tests
│   ├── agent_spec.rb
│   ├── clients/
│   │   └── http_spec.rb
│   └── tools/
│       ├── bash_spec.rb
│       ├── edit_spec.rb
│       └── ...
├── feature/       # Workflow behaviours
│   └── crayons_spec.rb
├── integration/   # Integration tests that require API keys. No `_spec.rb` suffix.
│   ├── coder.rb
│   ├── willie.rb
│   └── zai.rb
├── support/       # Test utilities and configuration
│   └── quiet_formatter.rb
└── spec_helper.rb
```

## Test Driven Development

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
- Look for dependency coupling. Use DI to decouple external classes
- 1 red and 1 green test for each scenario
- No duplicate tests

### Unit Tests
- Test individual classes
- File names match tested classes ... `agents.rb` => `agents_spec.rb`
- Mock all dependencies

## Feature Tests
- Test workflows and behaviour between classes
- Stub external services

### Integration Tests
- Requires external services
- Manually run
- Tests real behavior with real data
- do not use the `_spec.rb` suffix

## Limits to Testing

- Agents rely on external LLM APIs.
- Automated tests of behaviour that relies on LLMs is impossible.
- Don't test frameworks or external services

**All tests must pass before commits**

# Testing Crayons

This document defines testing standards that MUST be followed.

## Testing levels

Choosing the right test level depends on what you're testing:

### Unit Tests

**Choose when:**
- Testing a single class or method in isolation
- Fast, deterministic behavior required
- You need to verify edge cases and error handling
- Dependencies (if any) can be injected

**Rules:**
- ONLY test the subject class
- ALL dependencies must be injected as stubs/doubles
- Test only public methods
- Test behaviour and/or state
- Map class to spec file (agent.rb => unit/agent_spec.rb)
- IMPORTANT - Ruby standard library does not need to be stubbed!

**Example:**

Good Unit Test
```ruby
describe Thingy do
  it "returns FOO when the logger fails" do
    logger = instance_double(Logger, info: false)
    thingy = described_class.new(logger: logger)

    expect(thingy.generate).to eq("FOO")
  end
end
```

Bad Unit Test
```ruby
describe Thingy do
  subject { described_class.new }

  it "returns FOO when the logger fails" do
    allow(ThingyLogger).to receive(:info).and_return(false)

    result = subject.generate

    expect(result).to eq("FOO")
  end
end
```

### Component Tests

**Choose when:**
- Testing workflows between multiple classes
- Testing end-to-end behavior within a subsystem
- Verifying collaboration contracts between components
- Multiple internal components working together

**Rules:**
- Use real implementations of internal components
- Mock only external services (LLM APIs, HTTP, databases, network calls)
- Test behavior and collaboration between components
- Test contracts only - never test implementation of components.
- Focus on success/error paths
- Name based on flow being tested eg `spec/component/agent_call_loop_spec.rb`

**Example:**
```ruby
describe Crayons::Agent do
  describe "tool execution" do
    it "calls tool and returns result" do
      # Real internal tool - no mocking
      agent = described_class.new(:test, client: mock_llm_client)
      agent.call("Read the file test.rb")

      expect(agent.tool_calls).to include(:read_file)
    end
  end
end
```

### Integration Tests

**Choose when:**
- Testing with real external services (API keys required)
- Verifying compatibility with external systems
- Manual verification of production-like behavior
- Testing cannot be automated due to external dependencies

**Rules:**
- No `_spec.rb` suffix (excluded from automated runs)
- Use real APIs, real configurations
- Run manually with full environment setup
- Document expected behavior and any setup required
- Required for every external service

**Example:**
```ruby
# spec/integration/agent_workflows.rb (no _spec.rb suffix)

require_relative '../spec_helper'

describe "Agent workflows with real LLM" do
  it "successfully completes a simple task" do
    agent = Crayons::Agent.new(:coder)
    result = agent.call("Create a hello world function")

    expect(result).to include("SUCCESS")
  end
end
```

### Decision Framework
```
┌─────────────────────────────────────┐
│  What are you testing?              │
└─────────────────────────────────────┘
           │
           ├─ Single class/method? ────────────► Unit Test
           │   - Inject all dependencies as stubs/doubles
           │   - Fast, isolated
           │
           ├─ Multiple internal classes? ──────► Component Test
           │   - Real internal components
           │   - Mock only external services
           │
           └─ Real external systems? ───────────► Integration Test
                - Manual execution
                - Requires API keys/real services
```

## Test Structure

Tests are located in `spec/` directory:

```
spec/
├── unit/                 # Full isolated tests
│   ├── agent_spec.rb
│   ├── clients/
│   │   └── http_spec.rb
│   └── tools/
│       ├── bash_spec.rb
│       └── ...
├── component/            # Multiple internal components working together
│   └── logging_spec.rb
├── integration/          # Integration tests that require API keys. No `_spec.rb` suffix.
│   ├── willie.rb
│   └── ...
├── support/              # Test utilities and configuration
│   └── quiet_formatter.rb
└── spec_helper.rb
```

## General

- Tests provide important feedback for agents. Agents should always verify their work with `bin/verify`.
- `instance_variable_get` is a code smell in tests. If you need to test for state, make the state public via an `attr_reader`.
- Successful tests should be quiet - just returning the summary data (dots are ok too).
- Failing test should be loud - returning the full trace.
- You should always consider what a method is supposed to do before evaluating the test.

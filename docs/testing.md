# Testing Crayons

This document defines testing standards that MUST be followed.

## Testing levels

Choosing the right test level depends on what you're testing:

### Unit Tests

**Choose when:**
- Testing a single class or method in isolation
- Testing pure logic without external dependencies
- Fast, deterministic behavior required
- You need to verify edge cases and error handling

**Rules:**
- Stub all external dependencies (HTTP, database, file system)
- Test only public methods
- Test behaviour and/or state
- Map class to spec file (agent.rb => unit/agent_spec.rb)

**Example:**
```ruby
describe Crayons::CommandSanitizer do
  describe ".validate" do
    it "returns nil for safe commands" do
      expect(described_class.validate("ls -la")).to be_nil
    end
  end
end
```

### Feature Tests

**Choose when:**
- Testing workflows between multiple classes
- Testing end-to-end behavior within a subsystem
- External services exist but are too slow for unit tests
- You need to verify interaction patterns

**Rules:**
- Use real implementations of internal components
- Mock external services (LLM APIs, network calls) - see below
- Test behavior and collaboration contracts but not implementation
- Focus on success/error paths

**Example:**
```ruby
describe Crayons::Agent do
  describe "tool execution" do
    it "calls tool and returns result" do
      tool = instance_double(Crayons::Tool, name: :read)
      allow(tool).to receive(:execute).with(file_path: "test.rb").and_return(success: true)

      agent = described_class.new(:test, tools: [:read])
      result = agent.execute_tool(tool_name: :read, arguments: { file_path: "test.rb" })

      expect(result[:success]).to be true
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
           │   - Mock everything external
           │   - Fast, isolated
           │
           ├─ Multiple classes interacting? ────► Feature Test
           │   - Real internal code
           │   - Stubbed external services
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
├── feature/              # Workflow behaviours
│   └── crayons_spec.rb
├── integration/          # Integration tests that require API keys. No `_spec.rb` suffix.
│   ├── willie.rb
│   └── ...
├── support/              # Test utilities and configuration
│   └── quiet_formatter.rb
└── spec_helper.rb
```

## Mocking & Stubbing

Mocking and stubbing in unit tests indicates poor code design.

Avoid it whenever possibile. If you need to mock, redesign your code first.

Example:

**Bad - mocks implementation**

```ruby
class Find < Tool
  def call(input)
    dir = input[:path] || Dir.pwd
    # ...
  end
end

it "calls Open3 with correct command" do
  allow(Open3).to receive(:capture3).with("find /path -name '*.rb'")
  subject.call(pattern: "*.rb", path: "/path")
end
```

**Good - tests observable state**
```ruby
class Find < Tool
  attr_reader :dir

  def call(input)
    @dir = input[:path] || Dir.pwd
    # ...
  end
end

it "defaults to the project dir" do
  subject.call(pattern: "*.rb", path: "/project")
  expect(subject.dir).to eq("/project")
end
```

## General

Tests provide important feedback for agents. Agents should always verify their work with `bin/verify`.

Successful tests should be quite - just returning the summary data (dots are ok too).

Failing test should be loud - returning the full trace.

# Refactoring Plan: Client Interface Redesign

## Overview
Separate concerns: Agent manages conversation state (messages + system), Client handles API communication with explicit `chat(system:, messages:, tools:)` signature.

## Phase 1: Core Implementation

- [ ] Create `lib/ralph/clients/base.rb` (NEW)
  - Define `initialize(api_key:, url:, model:)` - raises NotImplementedError
  - Define `chat(system:, messages:, tools:)` - raises NotImplementedError

- [ ] Update `lib/ralph/clients/zai.rb`
  - Inherit from `Base`
  - Change `initialize` signature to `initialize(api_key: nil, url: nil, model: nil)`
  - Add defaults of ENV["ZAI_API_KEY"], https://api.z.ai/api/coding/paas/v4, GLM-4.7
  - Remove `env:` parameter
  - Remove `@tools` instance variable
  - Change `chat` signature to `chat(system:, messages:, tools:)`
  - Add system message to messages array before API call
  - Convert tools to schemas internally
  - Keep class methods: `convert_messages_to_api_format`, `convert_tools_to_schemas`, `parse_response`

- [ ] Update `lib/ralph/agent.rb`
  - In `initialize`: Add `@system = @instructions` (keep messages empty)
  - In `call`: Change `@messages = []` (no system prompt added to messages)
  - In `chat`: Pass `system: @system, messages: @messages, tools: @tool_instances` to `@client.chat`

- [ ] Update `lib/ralph/client.rb` (temporary)
  - Keep factory pattern for now
  - Update `Clients::Zai.new(tools:)` → `Clients::Zai.new(api_key:, url:, model:)`
  - Pass ENV values for defaults

## Phase 2: Test Updates

- [ ] Update `spec/ralph/clients/zai_spec.rb`
  - Update client initialization calls
  - Update `chat` calls to use new signature with `system:`, `messages:`, `tools:`
  - Verify system is added to messages array
  - Verify tools are converted internally

- [ ] Update `spec/ralph/agent_spec.rb`
  - Update `client.chat` expectations to receive keyword args `system:`, `messages:`, `tools:`
  - Verify system is passed separately from messages
  - Update all mock expectations

- [ ] Update `spec/ralph/tools/spawn_agent_spec.rb`
  - Update `Ralph::Clients::Zai.new` expectations (remove `tools:` parameter)
  - Update `client.chat` expectations to match new signature
  - Update all mock expectations across 19 occurrences

## Phase 3: Verification

- [ ] Run test suite
  - Execute `bundle exec rspec`
  - Ensure all tests pass with new interface

## Implementation Order

1. Create `lib/ralph/clients/base.rb` with base class interface
2. Refactor `lib/ralph/clients/zai.rb` to inherit from Base and implement new signature
3. Refactor `lib/ralph/agent.rb` to manage system separately
4. Update `lib/ralph/client.rb` factory to pass ENV defaults
5. Update all tests to use new client signature
6. Run tests and verify all pass

## Open Questions

1. Should Zai client default to these ENV vars?
   - `api_key: ENV['ZAI_API_KEY'] || ENV['OPENAI_API_KEY']`
   - `url: ENV['OPENAI_BASE_URL']`
   - `model: ENV['OPENAI_MODEL']`

2. How should temporary factory `Ralph::Client.new()` handle initialization?
   - Option A: No parameters (hardcode ENV defaults)
   - Option B: Accept optional `api_key:`, `url:`, `model:` parameters
   - Option C: Keep accepting `tools:` but ignore it for now

3. Should `Base` class add any validation (e.g., non-empty api_key)?

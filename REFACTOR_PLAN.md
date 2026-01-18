# Refactor Plan: Replace RubyLLM with Custom Client

## Goal
Replace RubyLLM dependency with custom async HTTP client for z.ai API to gain visibility into tool calls, responses, and context window management.

## New Components

### 1. HTTPClient (`lib/ralph/clients/http.rb`)
- Async HTTP client using HTTPX gem
- POST requests to z.ai chat completion endpoint
- Bearer authentication
- Returns parsed JSON responses
- Error handling: Raises exceptions on network failures, API errors, or invalid responses

### 2. Message Class (`lib/ralph/message.rb`)
- Represents any message in conversation (system, user, assistant, tool)
- Attributes: role, content, tool_calls, tool_call_id
- Helper method: `#tool_call?` returns true if tool_calls present
- Pattern follows RubyLLM::Message design
- Used by agent to build messages and by client for responses

### 3. Update ZaiClient (`lib/ralph/clients/zai.rb`)
- Owns: API configuration (API key, base URL, model)
- Owns: HTTP communication via HTTPClient
- Owns: Building request payloads
- Owns: Parsing API responses → Message object
- Owns: Converting tool classes → OpenAI schemas
- Does NOT handle tool calling or looping
- Returns Message object (role: :assistant, content, tool_calls)

### 4. Tool DSL (`lib/ralph/tool.rb`)
- Base class replacing `RubyLLM::Tool`
- DSL for `description` and `params`
- Generates OpenAI-compatible JSON Schema
- Validates and executes tools

### 5. Update Tools (`lib/ralph/tools/*.rb`)
- Replace `RubyLLM::Tool` with `Ralph::Tool`
- Keep existing DSL syntax
- Keep execute methods
- spawn_agent tool: No code changes needed; will automatically use refactored Agent

### 6. Update Agent (`lib/ralph/agent.rb`)
- Owns: Messages array (simple array of Message objects)
- Owns: Conversation loop and iteration logic
- Owns: Tool execution (detects tool_calls, executes tools)
- Owns: Logging tool calls and responses to stdout
  - Format: `[AGENT_ID] TOOL_CALL tool_name {params}`
  - Format: `[AGENT_ID] TOOL_RESPONSE tool_name {result}`
- Owns: Detecting completion (<promise>COMPLETE</promise>)
- Has `#call(prompt)` to start conversation
- Has `#chat(prompt)` for each turn
  - Appends prompt to messages array as user Message
  - Sends full messages array to ZaiClient
  - Appends assistant Message to messages array
  - Returns Message for Agent to process

## Flow: Agent#call

1. Initialize messages array
2. Add system prompt (agent instructions) as Message
 3. Loop (max_iterations):
    - Call `#chat(user_prompt)`
      - Append user Message to messages array
      - Send full messages array to ZaiClient
      - Append assistant Message to messages array
      - Return Message
    - If tool_calls:
      - Execute each tool with parameters
      - Convert tool return hash to tool Message (role: :tool, tool_call_id matches assistant's tool_call)
      - Append tool Messages to messages array
      - Continue loop
    - If completion marker: return success
    - If text response: continue loop
4. Max iterations reached: return failure

## Future: Message Injection

- Agent will check for queued messages before each loop iteration
- Design allows for injecting user messages to correct/guide agents
- Not implementing now, but architecture supports it


## Dependencies

**Add to Gemfile:** `gem "httpx"`
**Remove from Gemfile:** `gem "ruby_llm"`

## Testing

Follow TDD approach as defined in TESTING.md:

1. Write unit tests for each new component before implementation
2. Test structure per TESTING.md:
   - Unit tests for isolated behavior (Message, Tool DSL, HTTPClient)
   - Mock external dependencies (HTTPClient in ZaiClient tests, ZaiClient in Agent tests)
   - No integration tests requiring API keys during refactor
3. Test updates:
   - Update existing tool specs to mock Ralph::Tool instead of RubyLLM::Tool
   - Update Agent specs to mock ZaiClient instead of RubyLLM::Chat
   - Update Client specs to test new ZaiClient behavior
   - Add new specs for HTTPClient, Message, Tool DSL

## Implementation Order

1. HTTPClient
2. Message class
3. Tool DSL
4. ZaiClient
5. Update Tools
6. Update Agent
7. Remove RubyLLM dependency

## File Structure

```
lib/ralph/
├── message.rb             (NEW)
├── tool.rb                 (NEW)
├── agent.rb                (UPDATE)
├── client.rb               (KEEP)
├── clients/
│   ├── http.rb            (NEW)
│   └── zai.rb             (UPDATE)
└── tools/
    └── *.rb               (UPDATE - 8 files)
```

## Progress Tracking

- [x] HTTPClient
  - [x] Write tests
  - [x] Implement
  - [x] Run tests
  - [x] Commit
- [ ] Message class
  - [ ] Write tests
  - [ ] Implement
  - [ ] Run tests
  - [ ] Commit
- [ ] Tool DSL
  - [ ] Write tests
  - [ ] Implement
  - [ ] Run tests
  - [ ] Commit
- [ ] ZaiClient
  - [ ] Write tests
  - [ ] Implement
  - [ ] Run tests
  - [ ] Commit
- [ ] Update Tools
  - [ ] Update 8 tool files
  - [ ] Run tests
  - [ ] Commit
- [ ] Update Agent
  - [ ] Update Agent implementation
  - [ ] Run tests
  - [ ] Commit
- [ ] Remove RubyLLM dependency
  - [ ] Update Gemfile
  - [ ] Remove unused imports
  - [ ] Final test run
  - [ ] Commit

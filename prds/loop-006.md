---
status: completed
iteration: 1
---

# Agent Loop Logging (MVP) - PRD

## Overview

Add basic stdout logging to the agent loop to provide visibility during execution without polluting the LLM context.

## Goals

- [ ] See which agent is running
- [ ] Track iteration progress
- [ ] See when tools are invoked
- [ ] See completion status
- [ ] Ensure logs never return to calling agent

## User Stories

- As a developer, I want to see which agent is running, so I can identify who's executing
- As a developer, I want to see iteration numbers, so I can track progress and detect infinite loops
- As a developer, I want to see when tools are invoked, so I can understand what the agent is working on
- As a developer, I want to see completion status, so I can confirm the agent finished successfully

## Acceptance Criteria

- [ ] Log shows agent name at start
- [ ] Log shows iteration number
- [ ] Log shows tool name when invoked
- [ ] Log shows promise marker when complete
- [ ] Logs go to stdout only
- [ ] Log output does not appear in agent's return value
- [ ] Logs do not interfere with agent execution

## Technical Requirements

- Add `Agent#id` method returning `"[NAME:object_id]"` format
- Add 4 `puts` statements in `Agent#call`:
  1. Agent start
  2. Tool invocation (inside the loop)
  3. Completion detected
  4. Max iterations reached (if applicable)
- No logger class needed

## Implementation Notes

- Place `puts` calls outside the chat interface to ensure context isolation
- Use `@name` and `object_id` for agent identification
- Keep it simple - just stdout, no configuration, no file logging
- Test that logs appear in terminal but not in agent response

### Example Output

```
[CODER:70185238998860] Starting agent execution
[CODER:70185238998860] [Iteration 1] Tool: bash
[CODER:70185238998860] [Iteration 1] Tool: read_file
[CODER:70185238998860] [Iteration 2] Tool: bash
[CODER:70185238998860] Complete - <promise>COMPLETE</promise>
```

### File Structure

```
lib/ralph/
└── agent.rb           # Modified to add logging

spec/ralph/
└── agent_spec.rb      # Updated tests for logging behavior
```

## Edge Cases & Error Handling

- **Tool execution exception**: Continue logging, let the loop handle the error
- **Max iterations reached**: Log warning message before exiting

## Testing Requirements

- [ ] Test agent logs appear in stdout
- [ ] Test logs are not included in agent return value
- [ ] Test iteration count increments correctly
- [ ] Test tool invocation is logged
- [ ] Test completion status is logged
- [ ] Test max iterations warning is logged

## Dependencies

- **Existing Agent Implementation**: Modify `lib/ralph/agent.rb` to add simple stdout logging
- **Testing**: All existing tests must pass after implementation

## Future Enhancements (Out of Scope)

- [ ] Logger class with verbosity levels
- [ ] File logging
- [ ] Environment variable configuration
- [ ] Timestamps
- [ ] Tool execution timing
- [ ] Thread-safety for concurrent execution
- [ ] Structured logging (JSON)

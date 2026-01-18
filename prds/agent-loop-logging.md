# Agent Loop Logging - PRD

## Overview

Currently, agents execute in a loop with zero visibility during execution. Files simply appear, and there's no way to monitor progress, identify stuck agents, or understand what's happening at each iteration. This PRD adds structured logging to the agent loop, providing real-time visibility without polluting the LLM's context window.

## Goals

- [ ] Provide real-time visibility into agent execution progress
- [ ] Log iteration counts and loop status
- [ ] Track tool invocations and results
- [ ] Maintain zero impact on the agent's context window
- [ ] Support configurable verbosity levels
- [ ] Enable debugging of stuck or slow agents

## User Stories

- As a developer, I want to see which iteration an agent is on, so I know if the agent is stuck in an infinite loop or making progress
- As a developer, I want to see when tools are invoked and whether they succeed, so I can identify what the agent is working on
- As a developer, I want to toggle logging verbosity, so I can reduce noise when needed or get detailed information for debugging
- As a developer, I want logs written to a file, so I can review execution history after the agent completes

## Acceptance Criteria

- [ ] Logs display iteration number (e.g., `[Iteration 3/20]`)
- [ ] Logs show agent name at the start of execution
- [ ] Logs show when agent starts and completes execution
- [ ] Logs show `<promise>COMPLETE</promise>` or `<promise>FAILURE</promise>` status
- [ ] Logs show tool invocation when called (tool name and arguments)
- [ ] Logs show tool execution result (success/failure)
- [ ] Logs show max iterations reached warning when applicable
- [ ] Logs are written to STDOUT by default
- [ ] Logs can be written to a specified log file
- [ ] Log verbosity is configurable via environment variable or parameter
- [ ] Normal mode shows: iteration, tool calls, completion status
- [ ] Quiet mode shows: only completion status
- [ ] Verbose mode shows: iteration, tool calls with arguments, tool results, timing information
- [ ] No log content is included in the LLM context window
- [ ] Log output does not interfere with the agent's return value
- [ ] Logging can be disabled entirely via configuration

## Technical Requirements

### Logger Implementation

- Create a new `Ralph::Logger` class in `lib/ralph/logger.rb`
- Logger should support multiple output destinations (STDOUT, file, both)
- Logger should support verbosity levels: `:quiet`, `:normal` (default), `:verbose`
- Logger should be initialized with configuration options
- Logger methods should be thread-safe if parallel execution is added later

### Integration with Agent

- Modify `Agent#call` to initialize and use the logger
- Add iteration number tracking in the loop
- Log loop entry/exit points
- Log promise marker detection and completion status
- Log max iterations reached scenario

### Tool Call Logging

- Tools execute via RubyLLM's chat interface
- Hook into tool execution lifecycle (before/after tool calls)
- Log tool name and arguments at invocation time
- Log tool success/failure status after execution
- In verbose mode: log tool execution timing

### Configuration

- Environment variable `RALPH_LOG_LEVEL` controls verbosity (quiet/normal/verbose)
- Environment variable `RALPH_LOG_FILE` for file output path
- Configuration option passed to `Agent.new` for programmatic control
- Default: normal verbosity, STDOUT only

### Log Format

- Use consistent format with timestamps in verbose mode
- Example normal mode:
  ```
  [CODER] Starting agent execution
  [Iteration 1/20] Tool bash invoked: "ls -la"
  [Iteration 1/20] Tool bash completed successfully
  [Iteration 2/20] Tool read_file invoked: "lib/ralph/agent.rb"
  [Iteration 2/20] Tool read_file completed successfully
  [CODER] Complete - <promise>COMPLETE</promise>
  ```

- Example verbose mode:
  ```
  [2026-01-18 10:30:45] [CODER] Starting agent execution
  [2026-01-18 10:30:46] [Iteration 1/20] Tool bash invoked: "ls -la"
  [2026-01-18 10:30:47] [Iteration 1/20] Tool bash completed successfully (output: 23 lines, 1.2s)
  [2026-01-18 10:30:48] [Iteration 2/20] Tool read_file invoked: "lib/ralph/agent.rb"
  [2026-01-18 10:30:48] [Iteration 2/20] Tool read_file completed successfully (size: 2048 bytes, 0.1s)
  [2026-01-18 10:31:30] [CODER] Complete - <promise>COMPLETE</promise> (total time: 45s)
  ```

- Example quiet mode:
  ```
  [CODER] Complete - <promise>COMPLETE</promise>
  ```

## Implementation Notes

### Key Considerations

1. **Context Window Protection**: The logger must never inject content into the LLM's context. Logging happens outside the chat interface entirely.

2. **RubyLLM Integration**: Investigate RubyLLM's chat API to determine if there are hooks for tool call callbacks. If not, we may need to wrap tool registration or use middleware pattern.

3. **Agent Configuration**: The logger should be configurable per-agent instance, allowing different agents to have different logging settings.

4. **Non-Breaking Change**: Ensure existing agent code works without modification. Logging should be opt-in via configuration, with sensible defaults.

### Existing Code Patterns

- Follow the pattern in `lib/ralph/agent.rb` for attaching tools to the chat
- Use `@client.chat` from existing agent implementation
- Reference `spec/ralph/agent_spec.rb` for testing patterns around the agent loop

### File Structure

```
lib/ralph/
├── logger.rb          # New logger class
├── agent.rb           # Modified to integrate logging
└── tools.rb           # May need modification for tool call hooks

spec/ralph/
├── logger_spec.rb     # New logger tests
└── agent_spec.rb      # Updated tests for logging behavior
```

### Dependencies

- Standard Ruby `logger` library (for file logging)
- Ruby Time class (for timestamps)
- RubyLLM chat interface (need to verify available hooks)

## Edge Cases & Error Handling

- **Logger file creation fails**: Fall back to STDOUT with warning message
- **Invalid log level**: Default to `:normal` and log warning
- **Logger initialization error**: Proceed without logging (best effort)
- **Tool execution exception**: Log the exception, continue with next iteration
- **Agent interrupted during loop**: Log interruption reason and current iteration
- **Concurrent agent execution**: If multiple agents run concurrently, logs should not interleave (use thread-safe logging)

## Testing Requirements

### Unit Tests for Logger

- [ ] Test logger initialization with default settings
- [ ] Test logger initialization with custom settings (level, file)
- [ ] Test log output at different verbosity levels
- [ ] Test file logging writes to correct path
- [ ] Test thread-safe logging (if applicable)
- [ ] Test invalid log level handling

### Unit Tests for Agent Integration

- [ ] Test agent logs start of execution
- [ ] Test agent logs iteration numbers correctly
- [ ] Test agent logs tool invocations
- [ ] Test agent logs tool success/failure
- [ ] Test agent logs completion status
- [ ] Test agent logs max iterations reached
- [ ] Test quiet mode only shows completion
- [ ] Test verbose mode includes timing information
- [ ] Test logs are not included in agent context (verify chat content)

### Integration Tests

- [ ] Run actual agent with logging enabled, verify readable output
- [ ] Run agent with file logging, verify file creation and content
- [ ] Run agent with different verbosity levels, verify appropriate detail
- [ ] Run agent that completes successfully, verify log messages
- [ ] Run agent that fails/maxes out, verify appropriate failure logging

## Dependencies

- **RubyLLM API**: Need to investigate RubyLLM's chat interface to determine how to hook into tool execution lifecycle
- **Existing Agent Implementation**: Modify `lib/ralph/agent.rb` to integrate logger
- **Testing**: All existing tests must pass after implementation
- **Configuration**: Environment variable support for `RALPH_LOG_LEVEL` and `RALPH_LOG_FILE`

## Future Enhancements (Out of Scope)

- [ ] Structured logging format (JSON) for log aggregation tools
- [ ] Token usage tracking per iteration
- [ ] Progress bar/percentage completion
- [ ] Log rotation and retention policies
- [ ] Integration with monitoring systems (Datadog, New Relic, etc.)
- [ ] Web dashboard for real-time agent monitoring
- [ ] Historical execution replay/debugging from logs

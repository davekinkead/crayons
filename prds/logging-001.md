---
status: in_progress
iteration: 1
---

# PRD: Logging System

## Problem

Currently, Ralph uses `puts` statements scattered throughout the codebase for logging agent execution, tool calls, and HTTP requests. This pollutes stdout and potentially adds noise to agent context.

## Goal

Implement a structured logging system that:
- Does not pollute stdout
- Allows real-time monitoring via `tail -f`
- Enables post-mortem analysis of agent runs
- Provides high-detail logging (configurable levels)

## Requirements

### Functionality

1. Log file storage
   - Separate log files for different contexts
   - Default: `logs/ralph.log` for production
   - Test runs: `logs/test_ralph.log`

2. Real-time visibility
   - Logs must be written to files immediately
   - Must support `tail -f` monitoring

3. Persistent storage
   - Logs must persist across agent invocations
   - Daily log rotation to manage file size

4. Configurable detail levels
   - Support DEBUG, INFO, WARN, ERROR levels
   - Default to DEBUG for now
   - Configurable via environment variable

5. Single-line human-readable format
   - One log entry per line
   - Must include timestamp, log level, agent identifier, and event details
   - Context information should be appended but truncated if too long

### Configuration

Environment variables:
- `RALPH_LOG_LEVEL` - Controls detail level (DEBUG, INFO, WARN, ERROR)
- `RALPH_LOG_FILE` - Override default log file path

### Integration Points

Replace all `puts` statements in:
- Agent lifecycle (start, complete, max iterations)
- Tool execution (calls and responses)
- Client HTTP operations (requests, responses, errors)

Keep `puts` statements in integration test files - those are intentional demo output for stdout.

### Error Handling

Logging failures must not crash the application. Silent failure is acceptable to preserve main application stability.

## Success Criteria

- No `puts` output to stdout from agent operations
- Log files are created automatically
- `tail -f logs/ralph.log` works during agent execution
- Log level filtering works correctly
- Tests use separate log file
- All tests pass

## Out of Scope

- Query interface for logs (use grep, jq, or external tools)
- Log rotation beyond daily file naming
- External service integration (Datadog, Sentry, etc.)
- Structured JSON output

## Notes

The logger should be a singleton instance that can be accessed from anywhere in the codebase. Focus on simplicity and reliability over advanced features.

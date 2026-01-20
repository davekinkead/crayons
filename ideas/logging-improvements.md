# Logging Improvements for Crayons

## Agent Lifecycle Logging

### Current Issues
- Limited visibility - only shows when agent starts/completes
- No tracking of agent iterations or state transitions
- Tool execution logs lack context and outcome

### Proposed Improvements

#### 1. Agent Start/Complete Events
```
[INFO] [AGENT:id] Started: {prompt}
[INFO] [AGENT:id] Completed: {result_summary}
```

#### 2. Agent Iteration Tracking
```
[INFO] [AGENT:id] Iteration: {n}/{max_iterations}
```

#### 3. Tool Execution Logging
```
[INFO] [AGENT:id] Tool: {tool_name} {args}
[INFO] [AGENT:id] Tool Result: {success|failure} {summary}
```

#### 4. Agent Spawning
```
[INFO] [AGENT:id] Spawning: {agent_name} for: {purpose}
```

## Agent State Summary

### Current
- No high-level view of what agents are doing
- Can't track work across multiple PRDs/files

### Proposed
- Add "work tree" marker at start showing nested hierarchy
- Log agent state transitions with context
  - Reading PRD → Writing tests → Implementing → Running tests
- Include iteration/time information in INFO logs

## Structured Error Logging

### Current
- Generic error with full backtrace
- Hard to parse and understand at a glance

### Proposed
```
[ERROR] [AGENT:id] {error_type}: {message}
  Backtrace: {last_3_lines_compact}
```

Example:
```
[ERROR] [MARGE:123] NetworkError: Connection failed
  Backtrace: lib/crayons/clients/http.rb:30:in `Crayons::Clients::HTTP#post'
```

## Progress Indicators

### Current
- Can't tell how far along a task is

### Proposed
- Add `[INFO] [AGENT:id] Progress: {step}/{total}` - e.g., "Progress: 2/5 - Reading ARCHITECTURE.md"
- Color-coded status indicators:
  - 🟢 SUCCESS = Agent completed successfully
  - 🟡 IN PROGRESS = Agent is working
  - 🔴 BLOCKED = Agent blocked/waiting
  - 🟠 REVIEW = Agent reviewing/evaluating

## Reduce Log Bloat

### Current
- Every DEBUG message logs full payload (huge)
- Difficult to find relevant information

### Proposed
- Truncate large payloads to first 200 chars:
  ```
  [DEBUG] [AGENT:123] Payload: {"model":"GLM-4.7","messages":[{"role":"system"...
  ```
- Add context summarization: Only log key parts of payload

## Context Tracking

### Current
- No way to see which PRD/files are being worked on
- Agents operate in isolation without context awareness

### Proposed
- `[INFO] [AGENT:id] Working on: {prd_name}` - Show which PRD
- `[INFO] [AGENT:id] Context: {file_count}` - Show files accessed
- Track PRD context throughout execution

## Additional Notes

### Root Cause Analysis (2025-01-20)

The LISA agent gets stuck in an infinite loop when trying to use `bash` tool to run find/grep commands with output redirection. The `bash` tool has a security filter that rejects commands containing shell output redirection operators (`>`, `>>`, `<`, `|`, etc.).

**Fix Required:** Update `bash` tool to either:
1. Remove security restriction for safe commands (find, head, ls, cat, grep)
2. Provide better error messages explaining why command was rejected and suggest alternatives
3. Distinguish between dangerous redirection (writing files) and harmless redirection (piping output)

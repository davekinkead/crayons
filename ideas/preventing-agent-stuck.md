# Preventing Agents from Getting Stuck

## Common Stuck Patterns

### 1. Bash Tool Security Filter Loop
**Problem:** Agents try to use `bash` tool with commands containing output redirection (`>`, `>>`, `<`, `|`) and get rejected. They don't understand the error and retry the same command, creating an infinite loop.

**Example:**
```
find . -name "*.md" 2>/dev/null
→ ERROR: Command contains output redirection
→ Agent retries with same command
→ ERROR: Command contains output redirection
→ (loop continues)
```

**Solutions:**
1. **Fix bash tool** - Remove security restriction for safe commands (find, head, ls, cat, grep)
2. **Better error messages** - Explain why command was rejected and suggest alternatives
3. **Use dedicated tools** - Use `glob` and `grep` tools directly instead of wrapping in bash
4. **Agent instructions** - Teach agents to prefer glob/grep over bash for file operations

### 2. File Access Pattern Issues
**Problem:** Agent can't find a file, tries multiple approaches (different paths, file extensions, etc.) but keeps getting "File not found" errors.

**Example:**
```
read("./wrong/path.md") → File not found
read("prds/fix-httpx-error-response.md") → File not found
glob("./*httpx*") → No matches
(find loops through 10 variations)
```

**Solutions:**
1. **Check current directory** - Ensure agent knows where files are relative to
2. **Use glob strategically** - Start broad (`*.md`), then narrow down
3. **File existence check** - Before reading, verify file exists with `glob` first
4. **Agent instructions** - Teach systematic file location approach

### 3. Review/Validation Loop
**Problem:** Agent (like LISA) reads implementation, then tries to validate by searching for patterns that don't exist, repeats the process.

**Example:**
```
LISA reads http.rb
Tries: rg "NoMethodError" → no matches
Tries: rg "HTTPX::ErrorResponse" → error in pattern
Rereads http.rb
(continues loop)
```

**Solutions:**
1. **Focus on observable behavior** - What does the code actually DO, not what it might contain
2. **Don't validate implementation details** - Focus on code quality, not searching for specific patterns
3. **Clear success criteria** - Define exactly what to check, not how to verify it
4. **Time-box reviews** - Set max iteration or tool usage limits

### 4. Tool Error Recovery Loop
**Problem:** Agent tries command, gets error, doesn't adjust approach, retries identical command.

**Example:**
```
bash "2>/dev/null command" → ERROR
bash "2>/dev/null command" → ERROR
bash "2>/dev/null command" → ERROR
```

**Solutions:**
1. **Teach error adaptation** - When tool fails, try a DIFFERENT approach
2. **Multiple fallback strategies** - Provide 2-3 alternative ways to accomplish task
3. **Context escalation** - If stuck after N retries, ask for help or escalate
4. **Tool usage tracking** - Limit retries for same tool with same/similar commands

### 5. Missing Dependency/Limit Loops
**Problem:** Agent tries to use a tool/library that isn't available or requires configuration not present.

**Example:**
```
Calls non-existent tool → ERROR
Tries again → ERROR
Tries again → ERROR
```

**Solutions:**
1. **Environment detection** - Check if required tools exist before starting
2. **Graceful degradation** - Explain what's missing and suggest workaround
3. **Pre-check in agent instructions** - List available tools and when to use each
4. **Agent tool introspection** - Allow agents to discover available tools dynamically

## Agent-Level Preventive Measures

### 1. Clearer Error Messages
```
[ERROR] Command contains output redirection
Instead of:
Use glob tool for file operations
```

### 2. Iteration Limits
```
[INFO] [AGENT:id] Iteration: 3/10
[WARN] [AGENT:id] Approaching max iterations (8/10)
[ERROR] [AGENT:id] Max iterations reached, failing gracefully
```

### 3. State Tracking
```
[INFO] [AGENT:id] State: Reading PRD → Writing Tests → Implementing
[INFO] [AGENT:id] Spawning MARGE to implement changes
```

### 4. Tool Usage Caps
```
[INFO] [AGENT:id] Tool usage: 15/20 commands
[WARN] [AGENT:id] Approaching tool cap, batching operations
```

## System-Level Improvements

### 1. Bash Tool Enhancements
- Distinguish between dangerous redirection (writing) vs harmless redirection (piping to null)
- Allow safe commands with output redirection by default
- Better error messages: "Output redirection not allowed for command 'X'. Use glob tool instead."

### 2. Agent Instructions Update
Add to all agent personas:
```
## File Location Strategy

When working with files:
1. Use `glob` tool first to find files (broader pattern)
2. Then use `grep` or `read` for specific content
3. File paths are relative to current directory (starts with ./ or just filename)
4. Avoid bash commands for file operations - prefer glob/grep/read tools

## Error Recovery

If a tool command fails:
1. Try a different approach immediately - don't repeat the failing command
2. Use an alternative tool if available
3. If stuck after 3 attempts with different approaches, escalate to user
4. Log the error and what you tried before escalating

## Stuck Detection

Agent is considered "stuck" if:
- Repeats same action 5+ times
- Makes no progress for 10+ turns
- File not found after 10 attempts
- Tool errors with no adaptation

BART should detect stuck agents and:
1. Log warning: [WARN] [AGENT:name] Agent appears stuck (N iterations without progress)
2. Pause the cycle and report to CLANCY
3. Continue with next PRD if available
```

### 3. Better Tool Selection Guidance
```
For file operations:
❌ Don't use: bash find/grep/head/tail/cat
✅ Use: glob, grep, read tools

For directory operations:
❌ Don't use: bash ls/cd/pwd
✅ Use: glob to find patterns

For network operations:
❌ Don't use: bash curl/wget
✅ Use: These should be pre-built tools
```

## Monitoring & Alerting

Add to logging system:
```
[WARN] [BART] Agent {name} stuck in loop at iteration {n}
[WARN] [CLANCY] Multiple agents experiencing issues, check logs
```

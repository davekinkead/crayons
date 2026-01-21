# Common Agent Problems

Analysis of agent logs revealing frequent issues and patterns.

## 1. HTTPX Error Response Handling (Most Frequent)

**Error**: `undefined method 'status' for an instance of HTTPX::ErrorResponse`

**Frequency**: Very high - appears dozens of times in logs

**Impact**: Agents fail when HTTP client encounters error responses

**Status**: A PRD exists to fix this but appears incomplete

**Examples**:
```
[ERROR] [HTTP] Response handling error: undefined method 'status' for an instance of HTTPX::ErrorResponse
[ERROR] [AGENT:LISA:1592] Agent execution failed: Crayons::Clients::HTTP::NetworkError
```

**Root Cause**: HTTP client's `handle_response` method doesn't check if response object is an HTTPX::ErrorResponse before calling `.status` method

---

## 2. Network Timeouts

**Error**: `Timed out after 60 seconds`

**Frequency**: High (10+ occurrences)

**Impact**: Agents abort mid-execution due to slow API responses

**Location**: lib/crayons/clients/http.rb:82-96

**Examples**:
```
[ERROR] [HTTP] ErrorResponse: Timed out after 60 seconds
[ERROR] [HTTP] Response handling error: Network error: Timed out after 60 seconds
```

**Potential Solutions**:
- Increase timeout threshold
- Implement retry logic with exponential backoff
- Add timeout configuration per agent/task type

---

## 3. API Rate Limiting

**Error**: `API error (429): Too many API requests at the moment, please try again later`

**Frequency**: Medium-high (6-8 occurrences in recent logs)

**Impact**: Agents blocked from making LLM calls, halting progress

**Recovery**: Requires waiting and retry

**Examples**:
```
[ERROR] [HTTP] Error body: {"error":{"code":"1305","message":"Too many API requests at the moment, please try again later"}}
```

**Potential Solutions**:
- Implement automatic retry with exponential backoff
- Add rate limiting middleware to agent execution
- Queue agent requests to smooth out API calls
- Cache LLM responses where appropriate

---

## 4. ReadFile Tool Parameter Issues

**Errors**:
- `ArgumentError: unknown keyword: :section`
- `ArgumentError: unknown keyword: :line_count`
- `ArgumentError: unknown keywords: :offset, :limit`

**Frequency**: Medium (5-7 occurrences)

**Impact**: Tools fail when agents try to read files with unsupported parameters

**Root Cause**: Tool schema doesn't match what agents expect

**Examples**:
```
[ERROR] [AGENT:MARGE:704] Agent execution failed: ArgumentError: unknown keyword: :section
[ERROR] [AGENT:MARGE:1040] Agent execution failed: ArgumentError: unknown keyword: :line_count
[ERROR] [AGENT:MARGE:448] Agent execution failed: ArgumentError: unknown keywords: :offset, :limit
```

**Potential Solutions**:
- Update ReadFileTool to support offset/limit parameters
- Update tool definitions in agent frontmatter
- Add parameter validation with helpful error messages
- Document available parameters clearly

---

## 5. Max Iterations Reached

**Warning**: `[AGENT:XXX] Max iterations reached`

**Frequency**: Medium

**Impact**: Agents abandon tasks without completion

**Default limit**: 10 iterations

**Examples**:
```
[WARN] [CODER:1192] Max iterations reached
[WARN] [HAIKU:2144] Max iterations reached
```

**Potential Solutions**:
- Increase default max_iterations
- Make max_iterations configurable per agent
- Add task complexity detection to adjust iteration limit
- Implement iteration progress tracking and early success detection

---

## 6. API Authentication Failures

**Error**: `API error (401): token expired or incorrect`

**Frequency**: Low-medium (3-4 occurrences)

**Impact**: Agents cannot authenticate with LLM API

**Examples**:
```
[ERROR] [HTTP] Error body: {"error":{"code":"401","message":"token expired or incorrect"}}
[ERROR] [AGENT:LISA:280] Agent execution failed: Crayons::Clients::HTTP::APIError
```

**Potential Solutions**:
- Implement automatic token refresh
- Add pre-flight token validation
- Provide clear error messages with refresh instructions
- Add environment variable validation on startup

---

## 7. Async/HTTPX Integration Issues

**Errors**: Stream closure issues, fiber scheduling problems

**Frequency**: Low-medium

**Impact**: Unstable async HTTP client behavior

**Examples**:
```
[ERROR] [HTTP] ErrorResponse: stream 0 closed with error: no_error
[ERROR] [AGENT:MARGE:872] Agent execution failed: Crayons::Clients::HTTP::NetworkError
```

**Root Cause**: HTTPX async integration with fibers has edge cases

**Potential Solutions**:
- Improve error handling in fiber blocks
- Add connection pool cleanup
- Implement fallback to synchronous HTTP when async fails
- Add fiber lifecycle logging for debugging

---

## 8. Test Quality Gaps

**Issue**: Agents repeatedly flagged by APU for insufficient test coverage

**Examples**:
- Missing edge case tests for error extraction
- No verification of clean stdout/stderr
- Brittle assertions coupling to implementation details

**Impact**: Reduced confidence in code changes

**Examples from Logs**:
```
### APU: FAILURE
**Date:** 2025-06-18

Missing critical edge case tests for error message extraction. The spec has 2 tests for HTTPX::ErrorResponse but doesn't cover:
1. Fallback to `error_response.to_s` when error doesn't have a message method
2. Behavior when ErrorResponse doesn't respond to `:error` attribute
3. Nil error object scenarios
4. Empty error messages
```

**Potential Solutions**:
- Create test coverage reports before accepting PRDs
- Add automated test quality checks
- Implement mutation testing
- Add property-based testing for critical paths
- Require test examples for edge cases

---

## Priority Recommendations

1. **High Priority**: Fix HTTPX error response handling (blocks most failures)
2. **High Priority**: Add rate limiting and retry logic (frequent API issues)
3. **Medium Priority**: Fix ReadFile tool parameter mismatches
4. **Medium Priority**: Add better timeout handling
5. **Low Priority**: Improve iteration limit management
6. **Low Priority**: Strengthen test quality gates

---

## Analysis Notes

- Total log lines analyzed: ~1,300 across both log files
- Time period: January 20-21, 2026
- Most affected agents: CLANCY, MARGE, LISA, BART
- System overall health: Agents complete many tasks successfully but face recurring blocking issues
- Pattern: Many issues stem from HTTP client integration and error handling gaps

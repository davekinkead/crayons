---
status: complete
---

# Verification Tool for RSpec and Rubocop

## Objective
Create a verification tool that runs both `rspec` and `rubocop -A` commands, providing a single interface for agents to verify code quality without needing to make multiple bash tool calls.

## Success Criteria
- [x] Create VerificationTool with appropriate description and parameters
- [x] Tool runs `rspec` command and captures output/exit status
- [x] Tool runs `rubocop -A` command (autocorrect) and captures output/exit status
- [x] Returns combined results for both commands
- [x] Includes success/failure status for each verification step
- [x] Follows existing tool patterns and conventions
- [x] Has comprehensive test coverage
- [x] All tests pass (rspec)
- [x] Code follows rubocop standards

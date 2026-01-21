---
status: completed
---

# HTTP Client User-Agent Header

## Objective
Add a User-Agent header to the HTTP client using the format "User-Agent: opencode/{VERSION}" where VERSION is the Crayons::VERSION constant.

## Success Criteria
- [x] HTTP client includes User-Agent header in all requests
- [x] User-Agent format is "opencode/{VERSION}" (e.g., "opencode/0.1.0")
- [x] Uses Crayons::VERSION constant dynamically
- [x] Existing tests pass
- [x] New test verifies User-Agent header is set correctly
- [x] Code follows rubocop standards

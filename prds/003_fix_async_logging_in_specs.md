---
status: completed
---

# Fix Async Logging During Specs

## Objective
Fix the issue where Async gem logs warnings to stderr when exceptions are raised during specs, causing unwanted output that violates the "NEVER log output during specs" requirement.

## Success Criteria
- [x] Specs run with zero output to stdout/stderr (only show test summary)
- [x] All existing specs still pass
- [x] Exception handling in HTTP client preserves original error behavior
- [x] Code follows Ruby conventions and passes rubocop

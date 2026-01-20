---
status: completed
---

# Bash Sanitization Refinement and Module Extraction

## Objective
Extract bash command sanitization logic into a standalone module that can be shared by bash, grep, and glob tools. Refine the sanitization rules to allow development-friendly commands (cp, mv, brew, wget, curl) and allow rm without recursive flags.

## Success Criteria
- [x] Create Crayons::CommandSanitizer module with reusable validation logic
- [x] BashTool uses the shared CommandSanitizer module
- [x] GrepTool uses the shared CommandSanitizer module
- [x] GlobTool uses the shared CommandSanitizer module
- [x] Allow cp command (previously blocked)
- [x] Allow mv command (previously blocked)
- [x] Allow brew command (previously blocked)
- [x] Allow wget command (newly allowed)
- [x] Allow curl command (newly allowed)
- [x] Allow rm command ONLY without recursive flags (-r, -rf, -R, -rR, etc.)
- [x] Block rm with recursive flags (-r, -rf, -R, -fr, -rf, etc.)
- [x] All existing tests for bash, grep, and glob tools pass
- [x] New tests verify the refined sanitization rules work correctly
- [x] Code passes rubocop

## Feedback History

### APU: FAILURE
**Date:** 2025-06-20

The implementation meets all functional requirements from the PRD. However, there is a test quality issue:

**Issue: Testing private implementation details**

The `has_recursive_flag?` method is declared as private in the CommandSanitizer module, yet the specs in `command_sanitizer_spec.rb` test it as a public API with 10 separate test cases. This violates the TESTING.md principle that tests should focus on "outputs & behaviours, not implementation".

The behavior of recursive flag detection is already fully tested through the public `validate` method tests, which test both allowed and blocked rm commands. The private method tests are redundant and create a maintenance burden by coupling tests to implementation details that should be free to change.

Recommendation: Remove the entire `describe ".has_recursive_flag?"` block from `command_sanitizer_spec.rb` since the behavior is already tested through the public API.

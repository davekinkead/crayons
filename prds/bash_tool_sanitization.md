---
status: completed
---

# Bash Tool Command Sanitization

## Objective
Add command sanitization to the BashTool to prevent execution of dangerous commands that agents should be banned from using. This will protect the system from destructive operations while still allowing safe development commands.

## Success Criteria
- [x] BashTool forbids commands that modify/delete file system structures (rm, rmdir, dd, mkfs, etc.)
- [x] BashTool forbids commands that modify system configuration or package management
- [x] BashTool forbids commands that kill processes or restart services
- [x] BashTool forbids commands with pipe chains that could bypass validation
- [x] BashTool provides clear error messages when forbidden commands are blocked
- [x] BashTool allows safe commands (echo, ls, cat, grep, find, git status, etc.)
- [x] All existing bash_spec.rb tests pass
- [x] New tests verify dangerous commands are blocked
- [x] Code passes rubocop

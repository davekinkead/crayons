---
status: completed
---

# Create WILLIE Explorer Agent

## Objective
Create WILLIE - an explorer agent that, given a problem description, finds all relevant files and provides clear signposts for other agents including file names, paths, and key code snippets to grep for.

## Success Criteria
- [x] Create `agents/WILLIE.md` with agent definition including name, description, and tools
- [x] Register WILLIE agent in the system so it can be instantiated via `Crayons::Agent.new(:willie)`
- [x] WILLIE can be called with a problem description and returns relevant file information
- [x] Update AGENTS.md to include WILLIE in the available agents list
- [x] Tests pass for WILLIE agent instantiation and basic functionality
- [x] Rubocop passes

---
status: failed
---

# Create WILLI Explorer Agent

## Objective
Create WILLI - an explorer agent that, given a problem description, finds all relevant files and provides clear signposts for other agents including file names, paths, and key code snippets to grep for.

## Success Criteria
- [ ] Create `agents/WILLI.md` with agent definition including name, description, and tools
- [ ] Register WILLI agent in the system so it can be instantiated via `Crayons::Agent.new(:willi)`
- [ ] WILLI can be called with a problem description and returns relevant file information
- [ ] Update AGENTS.md to include WILLI in the available agents list
- [ ] Tests pass for WILLI agent instantiation and basic functionality
- [ ] Rubocop passes

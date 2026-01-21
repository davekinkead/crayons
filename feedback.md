# Commit Message Guidelines

When committing code changes, follow these conventions:

## Format
```
[Type] brief summary

- Detail 1
- Detail 2
- ...
```

## Types
- **Feature**: New functionality
- **Refactor**: Code restructuring without behavior change
- **Fix**: Bug fix
- **Test**: Adding or updating tests
- **Docs**: Documentation changes
- **Chore**: Maintenance tasks

## Examples

Good:
```
Refactor tool file naming and add tests
- Rename tool files from *_tool.rb to *.rb for consistency
- Add specs for bash, edit, haiku, read, write tools
- Remove obsolete built_in_spec.rb
- Update spec_helper.rb for new tool file structure
- Remove examples.txt (test output file)
```

Bad:
```
[loop-006] COMPLETED iteration 1 - Implemented basic stdout logging
```

## Why This Style
- Describes **what** changed, not **why** (the PRD explains why)
- Bullet points make the diff readable at a glance
- Semantic types help with release notes and git history
- More descriptive than PRD-focused messages

# Code Quality Standards

These standards define quality requirements for all code in the Crayons project.

### Method Design
- Single responsibility: One thing, well
- Max 20 lines per method
- Max 3 parameters (use options hash for more)
- Return early for guard clauses
- Avoid deep nesting (max 3 levels)

## Error Handling
- Raise specific exceptions
- Include context in error messages
- Handle expected errors gracefully
- Don't swallow exceptions

## Design Principles

For SOLID principles and architectural design patterns, see [architecture.md](architecture.md).

## Code Organization

### File Structure
- One public class per file
- Related modules in same directory
- Tests mirror production structure
- Shared utilities in dedicated files

### Module Organization
- Logical grouping by functionality
- Clear hierarchy
- Avoid circular dependencies
- Explicit requires

## Testing Requirements

(Note: See vision/testing.md for detailed test standards)
- All code must be tested
- Tests must cover edge cases
- Tests must be readable and maintainable

## Performance Considerations

- Avoid premature optimization
- Consider algorithmic complexity
- Cache expensive operations
- Use appropriate data structures

## Security

- Never commit secrets
- Validate all inputs
- Use parameterized queries
- Follow least privilege principle

## Documentation

- Public APIs documented
- Complex logic explained
- README for major components
- Changelog for breaking changes

## Git Commit Standards

### Commit Message Format

Follow this pattern for all commit messages:

```
Concise summary line (50-72 chars)

- Specific change 1 with context
- Specific change 2 with context
- Specific change 3 with context
```

Dot point the rationale, context, and impact of the changes.
This should help future developers understand why the change was
made. Do no include useless information like how many specs pass.

### Guidelines

- **Summary line**: Present tense, imperative mood (e.g., "Remove async logic", not "Removed" or "Removes")
- **Bullet points**: Present tense, describe what changed and why
- **Verification**: Always include test results and code quality checks
- **Rationale**: Explain the why, not just the what
- **Length**: Keep message focused but informative
```

Examples:
- "Remove async logic to resolve network issues" (good)
- "Fix: async removed" (too vague)
- "Removed async because it was broken" (wrong tense, weak rationale)

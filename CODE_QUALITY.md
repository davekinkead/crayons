# Code Quality Standards

These standards define quality requirements for all code in the Crayons project.

## Ruby Code Style

### Formatting
- Use standard Ruby indentation (2 spaces)
- Maximum line length: 100 characters
- One statement per line
- Empty lines between methods
- Spaces around operators

### Naming Conventions
- **Classes**: PascalCase (e.g., `AgentManager`)
- **Methods**: snake_case (e.g., `spawn_agent`)
- **Variables**: snake_case (e.g., `agent_name`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_ITERATIONS`)
- **Booleans**: Predicates end with `?` (e.g., `valid?`)
- **Destructive methods**: End with `!` (e.g., `update_status!`)

### Method Design
- Single responsibility: One thing, well
- Max 20 lines per method
- Max 3 parameters (use options hash for more)
- Return early for guard clauses
- Avoid deep nesting (max 3 levels)

## Architecture Principles

### Separation of Concerns
- Agents: Orchestrate and manage tasks
- Clients: Handle LLM API communication
- Tools: Perform specific actions
- Each component has clear boundaries

### Interface Design
- Use dependency injection
- Define clear public APIs
- Hide implementation details
- Favor composition over inheritance

### Error Handling
- Raise specific exceptions
- Include context in error messages
- Handle expected errors gracefully
- Don't swallow exceptions

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

(Note: See TESTING.md for detailed test standards)
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
- Test verification (e.g., "All 211 tests pass")
- Code quality (e.g., "Code passes rubocop with no violations")

Detailed paragraph explaining the rationale, context, and impact
of the changes. This should help future developers understand
why the change was made.
```

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

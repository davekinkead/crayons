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

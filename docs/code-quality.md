# Code Quality Standards

These standards define quality requirements for all code in the Crayons project.

## SOLID Principles for Ruby - Coding Agent Directives

### Single Responsibility Principle (SRP)
**Directive:** Each class should have one reason to change. Split classes that handle multiple concerns.

```ruby
# Bad - User class does too much
class User
  def save; end
  def send_welcome_email; end
  def generate_report; end
end

# Good - Each class has one job
class User
  def save; end
end

class UserNotifier
  def send_welcome_email(user); end
end

class UserReportGenerator
  def generate(user); end
end
```

**Agent rules:**
- If a class has methods dealing with different concerns (persistence, notification, validation, formatting), extract new classes
- Name classes after their single responsibility
- Watch for classes with multiple `require` statements importing unrelated gems

### Open/Closed Principle (OCP)
**Directive:** Classes should be open for extension but closed for modification. Use inheritance, modules, and composition instead of changing existing code.

```ruby
# Bad - Must modify class to add behavior
class PaymentProcessor
  def process(type, amount)
    case type
    when :credit_card then # ...
    when :paypal then # ...
    end
  end
end

# Good - Extend without modifying
class PaymentProcessor
  def process(payment_method, amount)
    payment_method.charge(amount)
  end
end

class CreditCardPayment
  def charge(amount); end
end

class PaypalPayment
  def charge(amount); end
end
```

**Agent rules:**
- Avoid adding new conditionals to existing methods
- Prefer polymorphism over case/if statements for type-based behavior
- Use duck typing and shared interfaces (modules)
- Create new classes rather than modifying old ones

### Liskov Substitution Principle (LSP)
**Directive:** Subclasses must be substitutable for their parent classes without breaking functionality.

```ruby
# Bad - Rectangle/Square violates LSP
class Rectangle
  attr_accessor :width, :height

  def area
    width * height
  end
end

class Square < Rectangle
  def width=(value)
    @width = @height = value  # Breaks expectations
  end
end

# Good - Composition instead
class Shape
  def area; raise NotImplementedError; end
end

class Rectangle < Shape
  def initialize(width, height)
    @width, @height = width, height
  end

  def area
    @width * @height
  end
end

class Square < Shape
  def initialize(side)
    @side = side
  end

  def area
    @side * @side
  end
end
```

**Agent rules:**
- Subclasses shouldn't strengthen preconditions or weaken postconditions
- Don't override methods to do nothing or raise unexpected exceptions
- If a subclass can't fulfill parent's contract, use composition instead
- Test subclasses with parent class test suite

### Interface Segregation Principle (ISP)
**Directive:** Don't force classes to depend on methods they don't use. In Ruby, create focused modules instead of fat interfaces.

```ruby
# Bad - Fat module forces unnecessary dependencies
module Worker
  def work; end
  def eat; end
  def sleep; end
end

class Robot
  include Worker  # Robots don't eat or sleep!
end

# Good - Focused modules
module Workable
  def work; end
end

module Biological
  def eat; end
  def sleep; end
end

class Human
  include Workable
  include Biological
end

class Robot
  include Workable
end
```

**Agent rules:**
- Create small, focused modules (mixins) with cohesive methods
- Clients should only know about methods they actually use
- Split large modules when not all implementers need all methods
- Use duck typing - don't require full interfaces when you only need one method

### Dependency Inversion Principle (DIP)
**Directive:** Depend on abstractions (interfaces/protocols) not concrete classes. Inject dependencies rather than hard-coding them.

```ruby
# Bad - High-level depends on low-level concrete class
class ReportGenerator
  def initialize
    @database = MySQL.new  # Hard dependency
  end

  def generate
    @database.query("SELECT * FROM users")
  end
end

# Good - Depend on abstraction, inject dependency
class ReportGenerator
  def initialize(database)
    @database = database  # Any object with #query
  end

  def generate
    @database.query("SELECT * FROM users")
  end
end

# Can now use any database that responds to #query
ReportGenerator.new(MySQL.new)
ReportGenerator.new(PostgreSQL.new)
ReportGenerator.new(MockDatabase.new)  # Easy testing!
```

**Agent rules:**
- Pass dependencies as constructor/method arguments instead of instantiating them internally
- Use dependency injection (constructor injection is clearest)
- Depend on duck types (objects that respond to certain methods) not concrete classes
- This makes testing easier - inject test doubles/mocks
- High-level business logic shouldn't import low-level infrastructure classes directly

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

## Combined Agent Checklist

When writing or reviewing Ruby code, check:
- [ ] Each class has one clear responsibility
- [ ] New features add new classes, not modify existing ones
- [ ] Subclasses work anywhere their parent would
- [ ] Modules are small and focused
- [ ] Dependencies are injected, not hard-coded
- [ ] Code is easy to test in isolation

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

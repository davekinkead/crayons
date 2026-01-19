# Define a custom formatter that extends RSpec's ProgressFormatter
# and suppresses verbose output while keeping details for failures
class QuietFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self,
    :example_passed, :example_failed, :example_pending, :dump_summary, :dump_failures, :seed

  # Suppress the "Randomized with seed" message
  def seed(seed_number)
    # Don't print anything
  end

  def dump_summary(summary)
    output.puts "\n#{summary.example_count} example#{'s' unless summary.example_count == 1}, " \
                "#{summary.failure_count} failure#{'s' unless summary.failure_count == 1}"
  end
end

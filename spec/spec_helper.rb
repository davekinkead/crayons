# frozen_string_literal: true
# Silence Ruby warnings for cleaner output
Warning[:deprecated] = false

require "dotenv/load"
require "rspec"

# Load custom formatters and support files AFTER rspec is loaded
Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }

# Debug: Check if QuietFormatter is loaded
puts "QuietFormatter defined: #{defined?(QuietFormatter)}" if ENV["DEBUG_RSPEC"]

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  # config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = false

  config.order = :random
  Kernel.srand config.seed

  # Configure output format: use custom QuietFormatter for minimal output
  # Shows only dots for passing tests and detailed info for failures
  config.formatter = QuietFormatter

  # Set up logging for tests
  config.before(:suite) do
    # Set test-specific log file
    ENV["RALPH_LOG_FILE"] = "logs/test_ralph.log"
    ENV["RALPH_LOG_LEVEL"] = "DEBUG"
  end
end

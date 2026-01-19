require 'spec_helper'
require_relative '../../lib/ralph'
require 'fileutils'

RSpec.describe Ralph::Logger do
  let(:log_dir) { File.join(Dir.tmpdir, "ralph_logs_#{Time.now.to_i}") }
  let(:log_file) { File.join(log_dir, "test.log") }

  before do
    # Set environment variables for testing
    @original_log_level = ENV['RALPH_LOG_LEVEL']
    @original_log_file = ENV['RALPH_LOG_FILE']
    ENV['RALPH_LOG_FILE'] = log_file
    ENV['RALPH_LOG_LEVEL'] = 'DEBUG'

    # Clear any existing singleton instance
    described_class.remove_instance

    # Ensure log directory exists
    FileUtils.mkdir_p(log_dir)
  end

  after do
    # Restore environment variables
    ENV['RALPH_LOG_LEVEL'] = @original_log_level
    ENV['RALPH_LOG_FILE'] = @original_log_file

    # Clean up test log files
    FileUtils.rm_rf(log_dir) if File.exist?(log_dir)
  end

  describe '.instance' do
    it 'returns a singleton instance' do
      logger1 = described_class.instance
      logger2 = described_class.instance
      expect(logger1).to be(logger2)
    end
  end

  describe '.remove_instance' do
    it 'removes the singleton instance' do
      logger1 = described_class.instance
      described_class.remove_instance
      logger2 = described_class.instance
      expect(logger1).not_to be(logger2)
    end
  end

  describe '#initialize' do
    it 'creates the log directory if it does not exist' do
      new_log_file = File.join(Dir.tmpdir, "ralph_new_#{Time.now.to_i}/test.log")
      ENV['RALPH_LOG_FILE'] = new_log_file

      logger = described_class.new
      expect(File.exist?(File.dirname(new_log_file))).to be true

      FileUtils.rm_rf(File.dirname(new_log_file))
    end

    it 'uses RALPH_LOG_FILE environment variable when set' do
      ENV['RALPH_LOG_FILE'] = log_file
      logger = described_class.new
      expect(logger.log_file_path).to eq(log_file)
    end

    it 'uses default log file when RALPH_LOG_FILE is not set' do
      ENV.delete('RALPH_LOG_FILE')
      logger = described_class.new
      expect(logger.log_file_path).to eq('logs/ralph.log')
    end

    it 'uses RALPH_LOG_LEVEL environment variable when set' do
      ENV['RALPH_LOG_LEVEL'] = 'WARN'
      logger = described_class.new
      expect(logger.level).to eq(:warn)
    end

    it 'defaults to DEBUG level when RALPH_LOG_LEVEL is not set' do
      ENV.delete('RALPH_LOG_LEVEL')
      logger = described_class.new
      expect(logger.level).to eq(:debug)
    end
  end

  describe '#log' do
    let(:logger) { described_class.instance }

    it 'truncates context information if too long' do
      long_context = 'x' * 1000
      truncated_context = 'x' * 100
      logger.log(:info, long_context, 'Message')
      content = File.read(log_file)
      expect(content).not_to include(long_context)
      expect(content).to include(truncated_context)
    end
  end

  describe 'error handling' do
    it 'does not crash when log file cannot be written' do
      # Use an invalid path
      invalid_path = '/nonexistent/directory/test.log'
      ENV['RALPH_LOG_FILE'] = invalid_path
      described_class.remove_instance
      logger = described_class.instance

      # Should not raise an error
      expect { logger.info('agent', 'Test message') }.not_to raise_error
    end

    it 'handles nil messages gracefully' do
      logger = described_class.instance
      expect { logger.info('agent', nil) }.not_to raise_error
    end
  end
end

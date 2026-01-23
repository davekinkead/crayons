# frozen_string_literal: true

require "logger"
require_relative "../../lib/logger"

RSpec.describe Crayons::Logger do
  describe "singleton instance" do
    it "returns the same instance on multiple calls" do
      instance1 = described_class.instance
      instance2 = described_class.instance
      expect(instance1).to be(instance2)
    end
  end

  describe "#log" do
    let(:log_file) { "tmp/test_logger.log" }
    let(:subject) { described_class.new }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CRAYONS_LOG_FILE").and_return(log_file)
    end

    after do
      FileUtils.rm_f(log_file)
      described_class.remove_instance
    end

    it "logs messages with context" do
      subject.log(1, "TestAgent", "Test message")
      expect(File.read(log_file)).to include("[TestAgent]")
      expect(File.read(log_file)).to include("Test message")
    end

    context "message truncation" do
      it "truncates messages to 500 characters for non-error levels" do
        long_message = "X" * 600
        subject.log(1, "TestAgent", long_message)
        log_content = File.read(log_file)
        expect(log_content).not_to include("X" * 600)
        expect(log_content).to include("X" * 500)
      end

      it "does not truncate ERROR level messages" do
        long_message = "X" * 600
        subject.log(3, "TestAgent", long_message)
        log_content = File.read(log_file)
        expect(log_content).to include("X" * 600)
      end
    end

    context "context truncation" do
      it "truncates context to 100 characters" do
        long_context = "A" * 150
        subject.log(1, long_context, "Test message")
        log_content = File.read(log_file)
        truncated_context = "A" * 100
        expect(log_content).to include("[#{truncated_context}]")
        expect(log_content).not_to include("A" * 150)
      end
    end
  end

  describe "#debug, #info, #warn, #error" do
    let(:log_file) { "tmp/test_logger_levels.log" }
    let(:subject) { described_class.new }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CRAYONS_LOG_FILE").and_return(log_file)
    end

    after do
      FileUtils.rm_f(log_file)
      described_class.remove_instance
    end

    it "logs at appropriate levels" do
      subject.debug("Agent1", "Debug message")
      subject.info("Agent2", "Info message")
      subject.warn("Agent3", "Warn message")
      subject.error("Agent4", "Error message")

      log_content = File.read(log_file)
      expect(log_content).to include("Debug message")
      expect(log_content).to include("Info message")
      expect(log_content).to include("Warn message")
      expect(log_content).to include("Error message")
    end
  end
end

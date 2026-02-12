# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/agent"
require_relative "../../lib/message"

RSpec.describe "Agent logging" do
  let(:mock_client) { instance_double(Crayons::Services::Zai) }
  let(:mock_logger) { instance_double(Crayons::Logger) }
  let(:agent) { Crayons::Agent.new(:test, client: mock_client) }

  before do
    allow(Crayons::Logger).to receive(:instance).and_return(mock_logger)
    allow(mock_logger).to receive(:debug)
    allow(mock_logger).to receive(:info)

    allow(Crayons::Tools).to receive(:new).and_call_original
  end

  describe "#call" do
    it "logs prompt at INFO level" do
      success_message = Crayons::Message.new(role: :assistant, content: "Task completed", complete: true)
      allow(mock_client).to receive(:chat).and_return(success_message)

      agent.call("Do something")

      expect(mock_logger).to have_received(:info).with(agent.id, "PROMPT: Do something")
    end

    it "logs response content at INFO level" do
      success_message = Crayons::Message.new(role: :assistant, content: "Task completed", complete: true)
      allow(mock_client).to receive(:chat).and_return(success_message)

      agent.call("Do something")

      expect(mock_logger).to have_received(:info).with(agent.id, "Task completed")
    end
  end

  describe "tool execution" do
    it "logs tool call at DEBUG level with name and arguments" do
      tool_call_message = Crayons::Message.new(
        role: :assistant,
        content: nil,
        complete: false,
        tool_calls: [{
          function: { name: "bash", arguments: '{"command":"ls"}' },
          id: "call_123",
          type: "function",
          index: 0
        }]
      )
      final_message = Crayons::Message.new(role: :assistant, content: "Files listed", complete: true)

      allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

      agent.call("List files")

      expect(mock_logger).to have_received(:debug).with(agent.id, /Tool: bash .*ls/)
    end

    it "logs tool result at DEBUG level with success/failure" do
      mock_bash_tool = instance_double(Crayons::Tool)
      allow(mock_bash_tool).to receive(:call).and_return({ success: true, result: "file1.rb\nfile2.rb" })
      allow(Crayons::Tools).to receive(:new).with(:bash).and_return(mock_bash_tool)

      tool_call_message = Crayons::Message.new(
        role: :assistant,
        content: nil,
        complete: false,
        tool_calls: [{
          function: { name: "bash", arguments: "{}" },
          id: "call_123",
          type: "function",
          index: 0
        }]
      )
      final_message = Crayons::Message.new(role: :assistant, content: "Done", complete: true)

      allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

      agent.call("Run command")

      expect(mock_logger).to have_received(:debug).with(agent.id, "Tool Result: SUCCESS - file1.rb\nfile2.rb")
    end

    it "logs failed tool result at DEBUG level" do
      mock_bash_tool = instance_double(Crayons::Tool)
      allow(mock_bash_tool).to receive(:call).and_return({ success: false, result: "Command failed" })
      allow(Crayons::Tools).to receive(:new).with(:bash).and_return(mock_bash_tool)

      tool_call_message = Crayons::Message.new(
        role: :assistant,
        content: nil,
        complete: false,
        tool_calls: [{
          function: { name: "bash", arguments: "{}" },
          id: "call_123",
          type: "function",
          index: 0
        }]
      )
      final_message = Crayons::Message.new(role: :assistant, content: "Done", complete: true)

      allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

      agent.call("Run command")

      expect(mock_logger).to have_received(:debug).with(agent.id, "Tool Result: FAILURE - Command failed")
    end
  end
end

RSpec.describe "Logger component" do
  let(:log_file) { "tmp/test_component_logger.log" }
  let(:logger) { Crayons::Logger.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("CRAYONS_LOG_FILE").and_return(log_file)
  end

  after do
    FileUtils.rm_f(log_file)
    Crayons::Logger.remove_instance
  end

  describe "singleton instance" do
    it "returns same instance on multiple calls" do
      instance1 = Crayons::Logger.instance
      instance2 = Crayons::Logger.instance
      expect(instance1).to be(instance2)
    end
  end

  describe ".truncate_message" do
    it "formats multiline text to single line" do
      text = "Line 1\nLine 2\nLine 3"
      expect(Crayons::Logger.truncate_message(text, 1)).to eq("Line 1 Line 2 Line 3")
    end

    it "removes leading/trailing whitespace" do
      text = "  \nLine 1\n  "
      expect(Crayons::Logger.truncate_message(text, 1)).to eq("Line 1")
    end

    it "handles multiple spaces between words" do
      text = "Word1   Word2    Word3"
      expect(Crayons::Logger.truncate_message(text, 1)).to eq("Word1 Word2 Word3")
    end

    it "converts tabs to spaces" do
      text = "Word1\tWord2\tWord3"
      expect(Crayons::Logger.truncate_message(text, 1)).to eq("Word1 Word2 Word3")
    end

    it "handles mixed whitespace" do
      text = "Line 1\n\t  Line 2\n   Line 3"
      expect(Crayons::Logger.truncate_message(text, 1)).to eq("Line 1 Line 2 Line 3")
    end

    it "does not truncate ERROR level messages" do
      long_message = "X" * 600
      result = Crayons::Logger.truncate_message(long_message, 3)
      expect(result.length).to eq(600)
      expect(result).to eq(long_message)
    end

    it "truncates non-ERROR messages to max length" do
      long_message = "X" * 600
      result = Crayons::Logger.truncate_message(long_message, 1)
      expect(result.length).to eq(500)
      expect(result).to eq("X" * 500)
    end

    it "does not truncate messages within max length" do
      short_message = "X" * 100
      expect(Crayons::Logger.truncate_message(short_message, 1)).to eq(short_message)
    end
  end

  describe "#log" do
    it "logs messages with context" do
      logger.log(1, "TestAgent", "Test message")
      expect(File.read(log_file)).to include("[TestAgent]")
      expect(File.read(log_file)).to include("Test message")
    end

    context "message truncation" do
      it "truncates messages to 500 characters for non-error levels" do
        long_message = "X" * 600
        logger.log(1, "TestAgent", long_message)
        log_content = File.read(log_file)
        expect(log_content).not_to include("X" * 600)
        expect(log_content).to include("X" * 500)
      end

      it "does not truncate ERROR level messages" do
        long_message = "X" * 600
        logger.log(3, "TestAgent", long_message)
        log_content = File.read(log_file)
        expect(log_content).to include("X" * 600)
      end
    end
  end

  describe "#debug, #info, #warn, #error" do
    it "logs at appropriate levels" do
      logger.debug("Agent1", "Debug message")
      logger.info("Agent2", "Info message")
      logger.warn("Agent3", "Warn message")
      logger.error("Agent4", "Error message")

      log_content = File.read(log_file)
      expect(log_content).to include("Debug message")
      expect(log_content).to include("Info message")
      expect(log_content).to include("Warn message")
      expect(log_content).to include("Error message")
    end
  end
end

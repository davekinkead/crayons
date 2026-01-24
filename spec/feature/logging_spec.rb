# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/agent"
require_relative "../../lib/message"

RSpec.describe "Agent logging" do
  let(:mock_client) { instance_double(Crayons::Clients::Zai) }
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

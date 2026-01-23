# frozen_string_literal: true

require_relative "../../lib/agent"
require_relative "../../lib/message"

RSpec.describe Crayons::Agent do
  let(:mock_client) { instance_double(Crayons::Clients::Zai) }
  let(:success_message) { Crayons::Message.new(role: :assistant, content: "Task completed", complete: true) }
  let(:failure_message) { Crayons::Message.new(role: :assistant, content: "An error occurred", complete: true) }
  describe ".new" do
    it "instantiates a named agent" do
      agent = described_class.new(:test)

      expect(agent).to be_a(described_class)
    end

    it "loads the agent from a markdown file" do
      agent = described_class.new(:test)

      expect(agent.name).to eq "TEST"
    end

    it "raises a NoAgentError if the agent doesn't exist" do
      expect { described_class.new(:nonexistent) }.to raise_error("Agent file not found")
    end
  end

  describe "#chat" do
    it "sends the system prompt, message history, and available tools to the client" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      agent = described_class.new(:test, client: mock_client)
      agent.instance_variable_set(:@message_history, [Crayons::Message.new(role: :user, content: "test")])

      agent.chat

      expect(mock_client).to have_received(:chat).with(
        system: be_a(String),
        messages: be_an(Array),
        tools: be_an(Array)
      )
    end
  end

  describe "#call" do
    it "accepts a prompt and returns the response" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      agent = described_class.new(:test, client: mock_client)
      response = agent.call("Do something")

      expect(response).to eq(success_message)
    end

    it "adds the prompt to the message history" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      agent = described_class.new(:test, client: mock_client)
      agent.call("First prompt")

      expect(mock_client).to have_received(:chat).once
      expect(agent.instance_variable_get(:@message_history)).to contain_exactly(
        have_attributes(role: :user, content: "First prompt"),
        have_attributes(role: :assistant, content: "Task completed")
      )
    end

    it "maintains message history across multiple calls" do
      response1 = Crayons::Message.new(role: :assistant, content: "Response 1", complete: true)
      response2 = Crayons::Message.new(role: :assistant, content: "Response 2", complete: true)
      
      allow(mock_client).to receive(:chat).and_return(response1, response2)

      agent = described_class.new(:test, client: mock_client)
      agent.call("First prompt")
      agent.call("Second prompt")

      expect(mock_client).to have_received(:chat).twice
      expect(agent.instance_variable_get(:@message_history)).to contain_exactly(
        have_attributes(role: :user, content: "First prompt"),
        have_attributes(role: :assistant, content: "Response 1"),
        have_attributes(role: :user, content: "Second prompt"),
        have_attributes(role: :assistant, content: "Response 2")
      )
    end

    it "loops to handle tool calls until complete" do
      mock_find_tool = instance_double(Crayons::Tool)
      allow(mock_find_tool).to receive(:name).and_return("find")
      allow(mock_find_tool).to receive(:description).and_return("Find files")
      allow(mock_find_tool).to receive(:params).and_return([])
      allow(Crayons::Tools).to receive(:new).with(:find).and_return(mock_find_tool)

      mock_test_tool = instance_double(Crayons::Tool)
      allow(mock_test_tool).to receive(:call).and_return({ success: true, result: "Tool executed" })
      allow(Crayons::Tools).to receive(:new).with(:test_tool).and_return(mock_test_tool)

      tool_call_message = Crayons::Message.new(
        role: :assistant,
        content: nil,
        complete: false,
        tool_calls: [{
          function: { name: "test_tool", arguments: "{}" },
          id: "call_123",
          type: "function",
          index: 0
        }]
      )
      final_message = Crayons::Message.new(role: :assistant, content: "Final answer", complete: true)

      allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

      agent = described_class.new(:test, client: mock_client)
      response = agent.call("Use a tool")

      expect(response).to eq(final_message)
      expect(mock_client).to have_received(:chat).twice
      expect(mock_test_tool).to have_received(:call).with({})
    end

    it "stops when message is complete" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      agent = described_class.new(:test, client: mock_client)
      agent.call("Simple task")

      expect(mock_client).to have_received(:chat).once
    end
  end
end

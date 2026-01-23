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

      agent.chat(messages: [Crayons::Message.new(role: :user, content: "test")])

      expect(mock_client).to have_received(:chat).with(
        system: be_a(String),
        messages: be_an(Array),
        tools: be_an(Array)
      )
    end
  end

  describe "#call" do
    before do
      allow(mock_client).to receive(:chat).and_return(success_message)
    end

    it "responds to call method" do
      agent = described_class.new(:test, client: mock_client)

      expect(agent).to respond_to(:call)
    end

    it "accepts a prompt string" do
      agent = described_class.new(:test, client: mock_client)

      expect { agent.call("test prompt") }.not_to raise_error
    end

    xit "calls the client with system, messages, and tools" do
      agent = described_class.new(:test, client: mock_client)

      agent.call("test prompt")

      expect(mock_client).to have_received(:chat).with(
        system: be_a(String),
        messages: be_an(Array),
        tools: be_an(Array)
      )
    end

    xit "returns a string" do
      agent = described_class.new(:test, client: mock_client)

      result = agent.call("test prompt")

      expect(result).to be_a(String)
    end

    xit "returns SUCCESS: format for successful operations" do
      agent = described_class.new(:test, client: mock_client)

      result = agent.call("simple test")

      expect(result).to start_with("SUCCESS:")
    end

    xit "includes the message content in SUCCESS response" do
      agent = described_class.new(:test, client: mock_client)

      result = agent.call("simple test")

      expect(result).to eq("SUCCESS: Task completed")
    end

    xit "returns FAILURE: format for failed operations" do
      allow(mock_client).to receive(:chat).and_return(failure_message)

      agent = described_class.new(:test, client: mock_client)

      result = agent.call("trigger failure")

      expect(result).to start_with("FAILURE:")
    end

    xit "includes detailed message in FAILURE response" do
      allow(mock_client).to receive(:chat).and_return(failure_message)

      agent = described_class.new(:test, client: mock_client)

      result = agent.call("trigger failure")

      expect(result).to match(/FAILURE: .+/)
    end
  end
end

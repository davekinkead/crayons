# frozen_string_literal: true

require_relative "../../lib/agent"
require_relative "../../lib/message"

RSpec.describe Crayons::Agent do
  let(:mock_client) { instance_double(Crayons::Services::Zai) }
  let(:success_message) { Crayons::Message.new(role: :assistant, content: "Task completed", complete: true) }
  let(:failure_message) { Crayons::Message.new(role: :assistant, content: "An error occurred", complete: true) }

  describe ".common_system_prompt" do
    it "returns a system prompt with SUCCESS/FAILURE instructions" do
      prompt = described_class.common_system_prompt

      expect(prompt).to include("SUCCESS:")
      expect(prompt).to include("FAILURE:")
    end

    it "returns a heredoc string" do
      expect(described_class.common_system_prompt).to be_a(String)
    end
  end

  # Approved as unit test
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

  describe "#id" do
    it "returns the agent id in lowercase format with object id number" do
      agent = described_class.new(:test)

      expect(agent.id).to eq "test-#{agent.object_id}"
    end
  end

  describe "#chat" do
    it "sends the system prompt, message history, and available tools to the client" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      agent = described_class.new(:test, client: mock_client)
      agent.call("test prompt")

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
      expect(mock_client).to have_received(:chat).with(
        system: be_a(String),
        messages: a_collection_including(have_attributes(role: :user, content: "First prompt")),
        tools: be_an(Array)
      )
    end

    it "stops when message is complete" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      agent = described_class.new(:test, client: mock_client)
      agent.call("Simple task")

      expect(mock_client).to have_received(:chat).once
    end
  end
end

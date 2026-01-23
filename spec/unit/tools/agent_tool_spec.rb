# frozen_string_literal: true

require_relative "../../../lib/tools/agent_tool"
require_relative "../../../lib/message"

RSpec.describe Crayons::Tools::AgentTool do
  let(:mock_client) { instance_double(Crayons::Clients::Zai) }
  let(:success_message) { Crayons::Message.new(role: :assistant, content: "Agent response", complete: true) }

  describe ".new" do
    it "instantiates an agent tool wrapper" do
      tool = described_class.new(:test)

      expect(tool).to be_a(Crayons::Tool)
    end

    it "loads agent config from markdown file" do
      tool = described_class.new(:test)

      expect(tool.name).to eq("TEST")
      expect(tool.description).to eq("An agent for internal tests only")
    end

    it "raises error for non-existent agent" do
      expect { described_class.new(:nonexistent) }.to raise_error("Agent file not found")
    end
  end

  describe "#name" do
    it "returns the agent name from config" do
      tool = described_class.new(:test)

      expect(tool.name).to eq("TEST")
    end
  end

  describe "#description" do
    it "returns the agent description from config" do
      tool = described_class.new(:test)

      expect(tool.description).to eq("An agent for internal tests only")
    end
  end

  describe "#params" do
    it "returns empty array (raw input accepted)" do
      tool = described_class.new(:test)

      expect(tool.params).to eq([])
    end
  end

  describe "#call" do
    it "sends string prompt to agent" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      tool = described_class.new(:test, client: mock_client)
      result = tool.call("test prompt")

      expect(result[:success]).to be true
      expect(result[:result]).to eq("Agent response")
    end

    it "converts hash input to string" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      tool = described_class.new(:test, client: mock_client)
      result = tool.call({ prompt: "value" })

      expect(result[:success]).to be true
      expect(mock_client).to have_received(:chat).once
    end

    it "returns success: false when agent raises error" do
      allow(mock_client).to receive(:chat).and_raise(StandardError, "Agent failed")

      tool = described_class.new(:test, client: mock_client)
      result = tool.call("test")

      expect(result[:success]).to be false
      expect(result[:result]).to eq("Agent failed")
    end

    it "each instance creates isolated agent" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      tool1 = described_class.new(:test, client: mock_client)
      tool2 = described_class.new(:test, client: mock_client)

      tool1.call("prompt 1")
      tool2.call("prompt 2")

      expect(mock_client).to have_received(:chat).twice
    end

    it "returns hash with success and result keys" do
      allow(mock_client).to receive(:chat).and_return(success_message)

      tool = described_class.new(:test, client: mock_client)
      result = tool.call("test")

      expect(result).to have_key(:success)
      expect(result).to have_key(:result)
    end
  end
end

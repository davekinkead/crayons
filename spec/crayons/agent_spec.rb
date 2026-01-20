# frozen_string_literal: true
require "spec_helper"
require_relative "../../lib/crayons"

RSpec.describe Crayons::Agent do
  describe "#initialize" do
    it "loads agent configuration from markdown file" do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(instance_double("Crayons::Clients::Zai"))
      agent = Crayons::Agent.new("CODER")
      expect(agent.name).to eq("CODER")
      expect(agent.description).to eq("An agent for writing or editing code")
    end

    it "loads tools from agent frontmatter" do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(instance_double("Crayons::Clients::Zai"))
      agent = Crayons::Agent.new("CODER")
      expect(agent.tools).to contain_exactly("bash", "read_file", "write_file", "edit_file", "grep", "glob")
    end

    it "loads agent instructions from markdown content" do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(instance_double("Crayons::Clients::Zai"))
      agent = Crayons::Agent.new("HAIKU")
      expect(agent.instructions).to include("You are a Haiku bot")
    end

    it "raises error for non-existent agent" do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(instance_double("Crayons::Clients::Zai"))
      expect { Crayons::Agent.new("nonexistent") }
        .to raise_error(/Agent file not found/)
    end
  end

  describe "#call" do
    let(:client) { instance_double("Crayons::Clients::Zai", chat: nil) }
    let(:agent) { Crayons::Agent.new("HAIKU", client: client) }

    it "appends default system prompt to instructions" do
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: Done", complete: true)
      )
      agent.call("Write me a haiku")
      expect(agent.instructions).to include("SUCCESS:")
      expect(agent.instructions).to include("FAILURE:")
    end

    it "preserves original agent instructions" do
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: Done", complete: true)
      )
      agent.call("Write me a haiku")
      expect(agent.instructions).to include("You are a Haiku bot")
    end

    it "sends instructions to LLM and returns response content" do
      expect(client).to receive(:chat).with(
        hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array))
      ).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: All done", complete: true)
      )

      response = agent.call("Write me a haiku")
      expect(response).to eq("SUCCESS: All done")
    end

    it "returns SUCCESS when LLM emits finish_reason=stop after multiple iterations" do
      call_count = 0
      expect(client).to receive(:chat).exactly(3).times do
        call_count += 1
        if call_count < 3
          Crayons::Message.new(role: :assistant, content: "Working...", complete: false)
        else
          Crayons::Message.new(role: :assistant, content: "SUCCESS: All done", complete: true)
        end
      end

      response = agent.call("Write me a haiku")
      expect(response).to eq("SUCCESS: All done")
    end

    it "continues looping when response is not complete" do
      call_count = 0
      expect(client).to receive(:chat).exactly(4).times do
        call_count += 1
        Crayons::Message.new(role: :assistant, content: "Still working...", complete: false)
      end

      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: All done", complete: true)
      )

      response = agent.call("Write me a haiku")
      expect(response).to eq("SUCCESS: All done")
      expect(call_count).to eq(4)
    end

    it "returns FAILURE with explanation when max iterations reached without success" do
      call_count = 0
      expect(client).to receive(:chat).exactly(5).times do
        call_count += 1
        Crayons::Message.new(role: :assistant, content: "Working...", complete: false)
      end

      expect(client).to receive(:chat).once.and_return(
        Crayons::Message.new(role: :assistant, content: "Explanation: task too complex", complete: true)
      )

      response = agent.call("Write me a haiku")
      expect(response).to start_with("FAILURE: Max iterations reached")
      expect(response).to include("Explanation: task too complex")
    end

    it "returns full content when response is complete" do
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: Done! Here is the haiku...", complete: true)
      )

      response = agent.call("Write me a haiku")
      expect(response).to eq("SUCCESS: Done! Here is the haiku...")
    end

    it "catches StandardError and returns FAILURE message with class, message and backtrace" do
      expect(client).to receive(:chat).and_raise(StandardError.new("Something went wrong"))

      response = agent.call("Write me a haiku")
      expect(response).to start_with("FAILURE: StandardError: Something went wrong")
      expect(response).to include("\n")
    end

    it "does NOT catch Exception and lets it propagate" do
      expect(client).to receive(:chat).and_raise(Exception.new("System failure"))

      expect { agent.call("Write me a haiku") }.to raise_error(Exception, "System failure")
    end
  end

  describe "#chat" do
    let(:client) { instance_double("Crayons::Clients::Zai", chat: nil) }
    let(:agent) { Crayons::Agent.new("HAIKU", client: client) }

    it "adds user message to messages when prompt is provided" do
      response = Crayons::Message.new(role: :assistant, content: "Hello")
      expect(client).to receive(:chat).and_return(response)

      agent.chat("test prompt")

      expect(agent.messages.map(&:role)).to include(:user)
    end

    it "adds response to messages" do
      response = Crayons::Message.new(role: :assistant, content: "Hello")
      expect(client).to receive(:chat).and_return(response)

      agent.chat("test prompt")

      expect(agent.messages.last).to eq(response)
    end

    it "returns the response from client" do
      response = Crayons::Message.new(role: :assistant, content: "Hello")
      expect(client).to receive(:chat).and_return(response)

      result = agent.chat("test prompt")

      expect(result).to eq(response)
    end

    it "does not add user message when prompt is nil" do
      response = Crayons::Message.new(role: :assistant, content: "Hello")
      expect(client).to receive(:chat).and_return(response)

      agent.chat(nil)

      expect(agent.messages.map(&:role)).not_to include(:user)
    end
  end

  describe "#max_iterations" do
    let(:client) { instance_double("Crayons::Clients::Zai") }

    before do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(client)
    end

    it "uses default max_iterations of 20 when not specified in frontmatter" do
      agent = Crayons::Agent.new("CODER", client: client)
      expect(agent.max_iterations).to eq(20)
    end

    it "uses custom max_iterations from agent frontmatter" do
      agent = Crayons::Agent.new("HAIKU", client: client)
      expect(agent.max_iterations).to eq(5)
    end

    it "raises error for non-positive max_iterations in frontmatter" do
      allow_any_instance_of(Crayons::Agent).to receive(:parse_frontmatter)
        .and_return([{
          "name" => "HAIKU",
          "description" => "test",
          "tools" => [],
          "max_iterations" => -1
        }, "test"])

      expect { Crayons::Agent.new("HAIKU", client: client) }
        .to raise_error(/max_iterations must be a positive integer/)
    end
  end
end

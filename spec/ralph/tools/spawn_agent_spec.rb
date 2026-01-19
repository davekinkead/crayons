# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/ralph"

RSpec.describe Ralph::SpawnAgentTool do
  let(:tool) { Ralph::SpawnAgentTool.new }

  describe "#execute" do
    context "with valid agent name" do
      let(:client_instance) { instance_double(Ralph::Clients::Zai, chat: nil) }

      before do
        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
      end

      it "spawns CODER with instructions and returns response" do
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "Working on it...", complete: false))
          .and_return(Ralph::Message.new(role: :assistant, content: "SUCCESS: Feature implemented", complete: true))

        result = tool.execute(agent_name: "CODER", instructions: "Implement a feature")

        expect(result).to start_with("SUCCESS:")
      end

      it "spawns REVIEWER with instructions and returns response" do
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "Reviewing code...", complete: false))
          .and_return(Ralph::Message.new(role: :assistant, content: "SUCCESS: Review complete", complete: true))

        result = tool.execute(agent_name: "REVIEWER", instructions: "Review this PRD")

        expect(result).to start_with("SUCCESS:")
      end

      it "returns FAILURE when spawned agent fails" do
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "Working...", complete: false))
          .and_return(Ralph::Message.new(role: :assistant, content: "Can't do it", complete: false))
          .and_return(Ralph::Message.new(role: :assistant, content: "Too hard", complete: false))

        result = tool.execute(agent_name: "CODER", instructions: "Impossible task")

        expect(result).to start_with("FAILURE: Max iterations reached")
      end

      it "spawns agent with fresh context (independent from parent)" do
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "SUCCESS: Task 1 done", complete: true))

        # First agent spawn
        result1 = tool.execute(agent_name: "CODER", instructions: "Task 1")

        # Second agent spawn should have fresh context
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "SUCCESS: Task 2 done", complete: true))

        result2 = tool.execute(agent_name: "CODER", instructions: "Task 2")

        expect(result1).to start_with("SUCCESS:")
        expect(result2).to start_with("SUCCESS:")
      end

      it "passes instructions to spawned agent" do
        allow(client_instance).to receive(:chat) do |args|
          # Check that instructions are in messages as user prompt
          expect(args[:messages].map(&:content).join).to include("Implement a user authentication system")
          Ralph::Message.new(role: :assistant, content: "SUCCESS: Auth system implemented", complete: true)
        end

        instructions = "Implement a user authentication system"
        tool.execute(agent_name: "CODER", instructions: instructions)
      end

      it "passes instructions to spawned agent" do
        allow(client_instance).to receive(:chat) do |args|
          # Check that instructions are in the messages as user prompt
          expect(args[:messages].map(&:content).join).to include("Implement a user authentication system")
          Ralph::Message.new(role: :assistant, content: "<promise>COMPLETE</promise>")
        end

        instructions = "Implement a user authentication system"
        tool.execute(agent_name: "CODER", instructions: instructions)
      end
    end

    context "with invalid agent name" do
      it "returns error message for non-existent agent" do
        result = tool.execute(agent_name: "NONEXISTENT", instructions: "Test")

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).not_to be_empty
        expect(result[:error]).to include("not found")
      end

      it "indicates available agents in error message" do
        result = tool.execute(agent_name: "INVALID", instructions: "Test")

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).not_to be_empty
        # Should mention available agents
        expect(result[:error]).to match(/CODER|REVIEWER|RALPH|HAIKU/)
      end

      it "handles string agent name" do
        client_instance = instance_double(Ralph::Clients::Zai, chat: nil)

        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "SUCCESS: Done", complete: true))

        result = tool.execute(agent_name: "CODER", instructions: "Test")

        expect(result).to start_with("SUCCESS:")
      end

      it "handles symbol agent name" do
        client_instance = instance_double(Ralph::Clients::Zai, chat: nil)

        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "SUCCESS: Done", complete: true))

        result = tool.execute(agent_name: :CODER, instructions: "Test")

        expect(result).to start_with("SUCCESS:")
      end
    end

    context "error handling" do
      it "handles agent initialization failure" do
        # Create a scenario where agent initialization fails
        allow(File).to receive(:exist?).and_return(false)

        result = tool.execute(agent_name: "CODER", instructions: "Test")

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).not_to be_empty
        expect(result[:error]).to include("Agent file not found")
      end

      it "handles empty instructions gracefully" do
        client_instance = instance_double(Ralph::Clients::Zai, chat: nil)

        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "FAILURE: No instructions provided", complete: true))

        result = tool.execute(agent_name: "CODER", instructions: "")

        expect(result).to start_with("FAILURE:")
      end
    end
  end

  describe "integration tests" do
    context "RALPH spawns CODER which returns COMPLETE" do
      it "successfully spawns CODER and gets COMPLETE response" do
        # This is an integration test that verifies full flow
        # In real usage, this would involve actual LLM calls
        # For now, we mock client

        client_instance = instance_double(Ralph::Clients::Zai, chat: nil)

        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "I'll implement this feature", complete: false))
          .and_return(Ralph::Message.new(role: :assistant, content: "SUCCESS: Feature implemented", complete: true))

        result = tool.execute(agent_name: "CODER", instructions: "Implement a feature")

        expect(result).to start_with("SUCCESS:")
      end
    end

    context "RALPH spawns CODER which returns FAILURE" do
      it "successfully spawns CODER and gets FAILURE response" do
        client_instance = instance_double(Ralph::Clients::Zai, chat: nil)

        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Ralph::Message.new(role: :assistant, content: "This is too complex", complete: false))
          .and_return(Ralph::Message.new(role: :assistant, content: "I cannot complete this", complete: false))
          .and_return(Ralph::Message.new(role: :assistant, content: "The task requires more context", complete: false))

        result = tool.execute(agent_name: "CODER", instructions: "Impossible task")

        expect(result).to start_with("FAILURE: Max iterations reached")
        expect(result).to include("The task requires more context")
      end
    end
  end
end

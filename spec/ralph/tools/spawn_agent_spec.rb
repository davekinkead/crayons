require 'spec_helper'
require_relative '../../../lib/ralph'

RSpec.describe Ralph::SpawnAgentTool do
  let(:tool) { Ralph::SpawnAgentTool.new }

  describe '#execute' do
    context 'with valid agent name' do
      let(:client_instance) { instance_double(Ralph::Clients::Zai) }
      let(:chat) { instance_double(RubyLLM::Chat) }

      before do
        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat).and_return(chat)
      end

      it 'spawns CODER with instructions and returns response' do
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask)
          .and_return(double("message", content: "Working on it..."))
          .and_return(double("message", content: "<promise>COMPLETE</promise>"))

        result = tool.execute(agent_name: 'CODER', instructions: 'Implement a feature')

        expect(result).to include("<promise>COMPLETE</promise>")
      end

      it 'spawns REVIEWER with instructions and returns response' do
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask)
          .and_return(double("message", content: "Reviewing code..."))
          .and_return(double("message", content: "<promise>COMPLETE</promise>"))

        result = tool.execute(agent_name: 'REVIEWER', instructions: 'Review this PRD')

        expect(result).to include("<promise>COMPLETE</promise>")
      end

      it 'returns FAILURE when spawned agent fails' do
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask)
          .and_return(double("message", content: "Working..."))
          .and_return(double("message", content: "Can't do it"))
          .and_return(double("message", content: "Too hard"))

        result = tool.execute(agent_name: 'CODER', instructions: 'Impossible task')

        expect(result).to start_with("<promise>FAILURE:")
      end

      it 'spawns agent with fresh context (independent from parent)' do
        # First agent spawn
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask)
          .and_return(double("message", content: "<promise>COMPLETE</promise>"))

        result1 = tool.execute(agent_name: 'CODER', instructions: 'Task 1')
        
        # Second agent spawn should have fresh context
        chat2 = instance_double(RubyLLM::Chat)
        allow(client_instance).to receive(:chat).and_return(chat2)
        allow(chat2).to receive(:with_tool).and_return(chat2)
        allow(chat2).to receive(:ask)
          .and_return(double("message", content: "<promise>COMPLETE</promise>"))
        
        result2 = tool.execute(agent_name: 'CODER', instructions: 'Task 2')

        expect(result1).to include("<promise>COMPLETE</promise>")
        expect(result2).to include("<promise>COMPLETE</promise>")
      end

      it 'passes instructions to spawned agent' do
        allow(chat).to receive(:with_tool).and_return(chat)
        
        instructions = 'Implement a user authentication system'
        allow(chat).to receive(:ask).and_return(double("message", content: "<promise>COMPLETE</promise>"))

        tool.execute(agent_name: 'CODER', instructions: instructions)

        # Verify instructions were passed to the agent
        expect(chat).to have_received(:ask).with(/#{Regexp.escape(instructions)}/m)
      end
    end

    context 'with invalid agent name' do
      it 'returns error message for non-existent agent' do
        result = tool.execute(agent_name: 'NONEXISTENT', instructions: 'Test')

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).not_to be_empty
        expect(result[:error]).to include('not found')
      end

      it 'indicates available agents in error message' do
        result = tool.execute(agent_name: 'INVALID', instructions: 'Test')

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).not_to be_empty
        # Should mention available agents
        expect(result[:error]).to match(/CODER|REVIEWER|RALPH|HAIKU/)
      end

      it 'handles string agent name' do
        client_instance = instance_double(Ralph::Clients::Zai)
        chat = instance_double(RubyLLM::Chat)
        
        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask).and_return(double("message", content: "<promise>COMPLETE</promise>"))

        result = tool.execute(agent_name: 'CODER', instructions: 'Test')

        expect(result).to include("<promise>COMPLETE</promise>")
      end

      it 'handles symbol agent name' do
        client_instance = instance_double(Ralph::Clients::Zai)
        chat = instance_double(RubyLLM::Chat)
        
        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask).and_return(double("message", content: "<promise>COMPLETE</promise>"))

        result = tool.execute(agent_name: :CODER, instructions: 'Test')

        expect(result).to include("<promise>COMPLETE</promise>")
      end
    end

    context 'error handling' do
      it 'handles agent initialization failure' do
        # Create a scenario where agent initialization fails
        allow(File).to receive(:exist?).and_return(false)

        result = tool.execute(agent_name: 'CODER', instructions: 'Test')

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).not_to be_empty
        expect(result[:error]).to include('Agent file not found')
      end

      it 'handles empty instructions gracefully' do
        client_instance = instance_double(Ralph::Clients::Zai)
        chat = instance_double(RubyLLM::Chat)
        
        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask).and_return(double("message", content: "<promise>FAILURE: No instructions provided</promise>"))

        result = tool.execute(agent_name: 'CODER', instructions: '')

        expect(result).to include("<promise>FAILURE:")
      end
    end
  end

  describe 'integration tests' do
    context 'RALPH spawns CODER which returns COMPLETE' do
      it 'successfully spawns CODER and gets COMPLETE response' do
        # This is an integration test that verifies the full flow
        # In real usage, this would involve actual LLM calls
        # For now, we mock the client
        
        client_instance = instance_double(Ralph::Clients::Zai)
        chat = instance_double(RubyLLM::Chat)
        
        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask)
          .and_return(double("message", content: "I'll implement this feature"))
          .and_return(double("message", content: "<promise>COMPLETE</promise>"))

        result = tool.execute(agent_name: 'CODER', instructions: 'Implement a feature')

        expect(result).to eq("<promise>COMPLETE</promise>")
      end
    end

    context 'RALPH spawns CODER which returns FAILURE' do
      it 'successfully spawns CODER and gets FAILURE response' do
        client_instance = instance_double(Ralph::Clients::Zai)
        chat = instance_double(RubyLLM::Chat)
        
        allow(Ralph::Clients::Zai).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_tool).and_return(chat)
        allow(chat).to receive(:ask)
          .and_return(double("message", content: "This is too complex"))
          .and_return(double("message", content: "I cannot complete this"))
          .and_return(double("message", content: "The task requires more context"))

        result = tool.execute(agent_name: 'CODER', instructions: 'Impossible task')

        expect(result).to start_with("<promise>FAILURE:")
        expect(result).to include("The task requires more context")
      end
    end
  end
end

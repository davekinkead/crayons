require 'spec_helper'
require_relative '../../lib/ralph'

RSpec.describe Ralph::Agent do
  describe '#initialize' do
    it 'loads agent configuration from markdown file' do
      agent = Ralph::Agent.new('CODER')
      expect(agent.name).to eq('CODER')
      expect(agent.description).to eq('An agent for writing or editing code')
    end

    it 'loads tools from agent frontmatter' do
      agent = Ralph::Agent.new('CODER')
      expect(agent.tools).to contain_exactly('bash', 'read_file', 'write_file', 'edit_file', 'grep', 'glob')
    end

    it 'loads agent instructions from markdown content' do
      agent = Ralph::Agent.new('HAIKU')
      expect(agent.instructions).to include('You are a Haiku bot')
    end

    it 'raises error for non-existent agent' do
      expect { Ralph::Agent.new('nonexistent') }
        .to raise_error(/Agent file not found/)
    end
  end

  describe '#call' do
    let(:client) { double("client", chat: chat) }
    let(:chat) { instance_double(RubyLLM::Chat) }
    let(:message) { double("message", content: "A haiku here") }
    let(:agent) { Ralph::Agent.new('HAIKU', client: client) }

    it 'sends instructions to LLM and returns response content' do
      allow(chat).to receive(:with_tool).and_return(chat)
      allow(chat).to receive(:ask).and_return(message)
      
      response = agent.call('Write me a haiku')
      expect(response).to eq("A haiku here")
      expect(chat).to have_received(:ask).with(/You are a Haiku bot.*Write me a haiku/m)
    end

    it 'includes agent instructions in context' do
      allow(chat).to receive(:with_tool).and_return(chat)
      allow(chat).to receive(:ask).and_return(double("message", content: "Response"))

      response = agent.call('Write me a haiku')
      expect(response).to eq("Response")
    end
  end
end

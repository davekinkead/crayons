require 'spec_helper'
require_relative '../../lib/ralph'

RSpec.describe Ralph::Agent do
  let(:agents_dir) { File.expand_path('../../agents', __dir__) }

  describe '#initialize' do
    it 'loads agent configuration from markdown file' do
      agent = Ralph::Agent.new('coder', agents_dir:)
      expect(agent.name).to eq('CODER')
      expect(agent.description).to eq('An agent for writing or editing code')
    end

    it 'loads tools from agent frontmatter' do
      agent = Ralph::Agent.new('coder', agents_dir:)
      expect(agent.tools).to contain_exactly('bash', 'read_file', 'write_file', 'edit_file')
    end

    it 'loads agent instructions from markdown content' do
      agent = Ralph::Agent.new('haiku', agents_dir:)
      expect(agent.instructions).to include('You are a Haiku bot')
    end

    it 'raises error for non-existent agent' do
      expect { Ralph::Agent.new('nonexistent', agents_dir:) }
        .to raise_error(/Agent file not found/)
    end
  end

  describe '#call' do
    let(:agent) { Ralph::Agent.new('haiku', agents_dir:) }
    let(:client) { instance_double(Ralph::Client) }
    let(:chat) { instance_double(RubyLLM::Chat) }

    before do
      allow(Ralph::Client).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return(chat)
    end

    it 'sends instructions to LLM and returns response' do
      allow(chat).to receive(:ask).and_return("A haiku here")
      
      response = agent.call('Write me a haiku')
      expect(response).to eq("A haiku here")
      expect(chat).to have_received(:ask).with(/You are a Haiku bot.*Write me a haiku/m)
    end

    it 'includes agent instructions in context' do
      allow(chat).to receive(:ask).and_return("Response")

      response = agent.call('Write me a haiku')
      expect(response).to eq("Response")
    end
  end
end

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
      allow(chat).to receive(:ask).and_return(double("message", content: "<promise>COMPLETE</promise>"))

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
      expect(chat).to have_received(:ask).with(/You are a Haiku bot.*Write me a haiku/m)
    end

    it 'returns COMPLETE when LLM emits promise marker after multiple iterations' do
      allow(chat).to receive(:with_tool).and_return(chat)
      allow(chat).to receive(:ask)
        .and_return(double("message", content: "Working..."))
        .and_return(double("message", content: "Still working..."))
        .and_return(double("message", content: "<promise>COMPLETE</promise>"))

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
    end

    it 'continues looping when response does not contain promise marker' do
      allow(chat).to receive(:with_tool).and_return(chat)
      call_count = 0
      allow(chat).to receive(:ask) do
        call_count += 1
        if call_count < 5
          double("message", content: "Still working...")
        else
          double("message", content: "<promise>COMPLETE</promise>")
        end
      end

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
      expect(call_count).to eq(5)
    end

    it 'returns FAILURE with explanation when max iterations reached without success' do
      allow(chat).to receive(:with_tool).and_return(chat)
      allow(chat).to receive(:ask)
        .and_return(double("message", content: "Working..."))
        .and_return(double("message", content: "Still working..."))
        .and_return(double("message", content: "Can't finish"))
        .and_return(double("message", content: "I need more time"))
        .and_return(double("message", content: "Explanation: task too complex"))

      response = agent.call('Write me a haiku')
      expect(response).to start_with("<promise>FAILURE:")
      expect(response).to include("Explanation: task too complex")
    end

    it 'strips whitespace from LLM response before checking for promise marker' do
      allow(chat).to receive(:with_tool).and_return(chat)
      allow(chat).to receive(:ask).and_return(double("message", content: "  <promise>COMPLETE</promise>  "))

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
    end

    it 'returns COMPLETE marker exactly (not pass-through with content)' do
      allow(chat).to receive(:with_tool).and_return(chat)
      allow(chat).to receive(:ask).and_return(double("message", content: "Done! <promise>COMPLETE</promise>"))

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
    end
  end

  describe '#max_iterations' do
    let(:client) { double("client", chat: instance_double(RubyLLM::Chat)) }

    it 'uses default max_iterations of 20 when not specified in frontmatter' do
      agent = Ralph::Agent.new('CODER', client: client)
      expect(agent.max_iterations).to eq(20)
    end

    it 'uses custom max_iterations from agent frontmatter' do
      agent = Ralph::Agent.new('HAIKU', client: client)
      expect(agent.max_iterations).to eq(5)
    end

    it 'raises error for non-positive max_iterations in frontmatter' do
      allow_any_instance_of(Ralph::Agent).to receive(:parse_frontmatter)
        .and_return([{
          'name' => 'HAIKU',
          'description' => 'test',
          'tools' => [],
          'max_iterations' => -1
        }, 'test'])

      expect { Ralph::Agent.new('HAIKU', client: client) }
        .to raise_error(/max_iterations must be a positive integer/)
    end
  end
end


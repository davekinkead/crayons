require 'spec_helper'
require_relative '../../lib/ralph'

RSpec.describe Ralph::Agent do
  describe '#initialize' do
    it 'loads agent configuration from markdown file' do
      allow(Ralph::Client).to receive(:new).and_return(instance_double("Ralph::Clients::Zai"))
      agent = Ralph::Agent.new('CODER')
      expect(agent.name).to eq('CODER')
      expect(agent.description).to eq('An agent for writing or editing code')
    end

    it 'loads tools from agent frontmatter' do
      allow(Ralph::Client).to receive(:new).and_return(instance_double("Ralph::Clients::Zai"))
      agent = Ralph::Agent.new('CODER')
      expect(agent.tools).to contain_exactly('bash', 'read_file', 'write_file', 'edit_file', 'grep', 'glob')
    end

    it 'loads agent instructions from markdown content' do
      allow(Ralph::Client).to receive(:new).and_return(instance_double("Ralph::Clients::Zai"))
      agent = Ralph::Agent.new('HAIKU')
      expect(agent.instructions).to include('You are a Haiku bot')
    end

    it 'raises error for non-existent agent' do
      allow(Ralph::Client).to receive(:new).and_return(instance_double("Ralph::Clients::Zai"))
      expect { Ralph::Agent.new('nonexistent') }
        .to raise_error(/Agent file not found/)
    end
  end

  describe '#call' do
    let(:client) { instance_double("Ralph::Clients::Zai", chat: nil) }
    let(:agent) { Ralph::Agent.new('HAIKU', client: client) }

    it 'sends instructions to LLM and returns response content' do
      expect(client).to receive(:chat).with(
        hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array))
      ).and_return(
        Ralph::Message.new(role: :assistant, content: "<promise>COMPLETE</promise>")
      )

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
    end

    it 'returns COMPLETE when LLM emits promise marker after multiple iterations' do
      call_count = 0
      expect(client).to receive(:chat).exactly(3).times do |args|
        call_count += 1
        if call_count < 3
          Ralph::Message.new(role: :assistant, content: "Working...")
        else
          Ralph::Message.new(role: :assistant, content: "<promise>COMPLETE</promise>")
        end
      end

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
    end

    it 'continues looping when response does not contain promise marker' do
      call_count = 0
      expect(client).to receive(:chat).exactly(4).times do |args|
        call_count += 1
        Ralph::Message.new(role: :assistant, content: "Still working...")
      end

      expect(client).to receive(:chat).and_return(
        Ralph::Message.new(role: :assistant, content: "<promise>COMPLETE</promise>")
      )

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
      expect(call_count).to eq(4)
    end

    it 'returns FAILURE with explanation when max iterations reached without success' do
      call_count = 0
      expect(client).to receive(:chat).exactly(5).times do |args|
        call_count += 1
        Ralph::Message.new(role: :assistant, content: "Working...")
      end

      expect(client).to receive(:chat).once.and_return(
        Ralph::Message.new(role: :assistant, content: "Explanation: task too complex")
      )

      response = agent.call('Write me a haiku')
      expect(response).to start_with("<promise>FAILURE:")
      expect(response).to include("Explanation: task too complex")
    end

    it 'strips whitespace from LLM response before checking for promise marker' do
      expect(client).to receive(:chat).and_return(
        Ralph::Message.new(role: :assistant, content: "  <promise>COMPLETE</promise>  ")
      )

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
    end

    it 'returns COMPLETE marker exactly (not pass-through with content)' do
      expect(client).to receive(:chat).and_return(
        Ralph::Message.new(role: :assistant, content: "Done! <promise>COMPLETE</promise>")
      )

      response = agent.call('Write me a haiku')
      expect(response).to eq("<promise>COMPLETE</promise>")
    end
  end

  describe '#chat' do
    let(:client) { instance_double("Ralph::Clients::Zai", chat: nil) }
    let(:agent) { Ralph::Agent.new('HAIKU', client: client) }

    it 'adds user message to messages when prompt is provided' do
      response = Ralph::Message.new(role: :assistant, content: 'Hello')
      expect(client).to receive(:chat).and_return(response)

      agent.chat('test prompt')

      expect(agent.messages.map(&:role)).to include(:user)
    end

    it 'adds response to messages' do
      response = Ralph::Message.new(role: :assistant, content: 'Hello')
      expect(client).to receive(:chat).and_return(response)

      agent.chat('test prompt')

      expect(agent.messages.last).to eq(response)
    end

    it 'returns the response from client' do
      response = Ralph::Message.new(role: :assistant, content: 'Hello')
      expect(client).to receive(:chat).and_return(response)

      result = agent.chat('test prompt')

      expect(result).to eq(response)
    end

    it 'does not add user message when prompt is nil' do
      response = Ralph::Message.new(role: :assistant, content: 'Hello')
      expect(client).to receive(:chat).and_return(response)

      agent.chat(nil)

      expect(agent.messages.map(&:role)).not_to include(:user)
    end
  end

  describe '#max_iterations' do
    let(:client) { instance_double("Ralph::Client") }

    before do
      allow(Ralph::Client).to receive(:new).and_return(client)
    end

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

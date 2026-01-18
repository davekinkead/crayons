require 'spec_helper'
require_relative '../../lib/ralph/clients/zai'
require_relative '../../lib/ralph/message'

RSpec.describe Ralph::Clients::Zai do
  describe '#initialize' do
    it 'stores API configuration' do
      env = {
        'ZAI_API_KEY' => 'test-key',
        'OPENAI_BASE_URL' => 'https://api.test.com',
        'OPENAI_MODEL' => 'gpt-4'
      }

      client = described_class.new(env:)
      expect(client.instance_variable_get(:@api_key)).to eq('test-key')
      expect(client.instance_variable_get(:@base_url)).to eq('https://api.test.com')
      expect(client.instance_variable_get(:@model)).to eq('gpt-4')
    end

    it 'creates HTTPClient instance' do
      env = {
        'ZAI_API_KEY' => 'test-key',
        'OPENAI_BASE_URL' => 'https://api.test.com'
      }

      client = described_class.new(env:)
      expect(client.instance_variable_get(:@http_client)).to be_a(Ralph::Clients::HTTP)
    end
  end

  describe '#chat' do
    let(:env) { { 'ZAI_API_KEY' => 'test-key', 'OPENAI_BASE_URL' => 'https://api.test.com' } }
    let(:client) { described_class.new(env:) }

    it 'returns Message object from API response' do
      messages = [Ralph::Message.new(role: :user, content: 'test')]
      api_response = {
        "choices" => [{
          "message" => {
            "role" => "assistant",
            "content" => "Hello!"
          }
        }]
      }

      allow(client.instance_variable_get(:@http_client)).to receive(:post).and_return(api_response)

      response = client.chat(messages)
      expect(response).to be_a(Ralph::Message)
      expect(response.role).to eq(:assistant)
      expect(response.content).to eq("Hello!")
    end

    it 'handles tool_calls in response' do
      messages = [Ralph::Message.new(role: :user, content: 'test')]
      api_response = {
        "choices" => [{
          "message" => {
            "role" => "assistant",
            "tool_calls" => [
              {
                "id" => "call_123",
                "function" => {
                  "name" => "bash",
                  "arguments" => '{"command": "ls"}'
                }
              }
            ]
          }
        }]
      }

      allow(client.instance_variable_get(:@http_client)).to receive(:post).and_return(api_response)

      response = client.chat(messages)
      expect(response).to be_a(Ralph::Message)
      expect(response.role).to eq(:assistant)
      expect(response.tool_call?).to be true
      expect(response.tool_calls).to eq([
        {
          "id" => "call_123",
          "function" => {
            "name" => "bash",
            "arguments" => '{"command": "ls"}'
          }
        }
      ])
    end
  end

  describe '#convert_messages_to_api_format' do
    let(:env) { { 'ZAI_API_KEY' => 'test-key', 'OPENAI_BASE_URL' => 'https://api.test.com' } }
    let(:client) { described_class.new(env:) }

    it 'converts Message objects to API format' do
      messages = [
        Ralph::Message.new(role: :system, content: 'You are helpful'),
        Ralph::Message.new(role: :user, content: 'test'),
        Ralph::Message.new(role: :assistant, content: 'Hello', tool_calls: [{ id: '1', function: { name: 'bash', arguments: '{}' } }])
      ]

      api_format = client.send(:convert_messages_to_api_format, messages)
      expect(api_format).to eq([
        { role: 'system', content: 'You are helpful' },
        { role: 'user', content: 'test' },
        { role: 'assistant', content: 'Hello', tool_calls: [{ id: '1', function: { name: 'bash', arguments: '{}' } }] }
      ])
    end
  end
end

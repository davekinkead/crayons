require 'spec_helper'
require_relative '../../lib/ralph/message'

RSpec.describe Ralph::Message do
  describe '#initialize' do
    it 'stores role' do
      message = described_class.new(role: :user, content: 'hello')
      expect(message.role).to eq(:user)
    end

    it 'stores content' do
      message = described_class.new(role: :user, content: 'hello')
      expect(message.content).to eq('hello')
    end

    it 'stores tool_calls' do
      tool_calls = [{ id: '123', function: { name: 'bash', arguments: '{}' } }]
      message = described_class.new(role: :assistant, tool_calls:)
      expect(message.tool_calls).to eq(tool_calls)
    end

    it 'stores tool_call_id' do
      message = described_class.new(role: :tool, tool_call_id: '123')
      expect(message.tool_call_id).to eq('123')
    end
  end

  describe '#tool_call?' do
    it 'returns true when tool_calls present' do
      tool_calls = [{ id: '123', function: { name: 'bash', arguments: '{}' } }]
      message = described_class.new(role: :assistant, tool_calls:)
      expect(message.tool_call?).to be true
    end

    it 'returns false when tool_calls absent' do
      message = described_class.new(role: :user, content: 'hello')
      expect(message.tool_call?).to be false
    end
  end
end


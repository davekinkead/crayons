require 'spec_helper'
require_relative '../../lib/ralph/tool'

RSpec.describe Ralph::Tool do
  describe '.description' do
    it 'sets description' do
      test_tool = Class.new(described_class) do
        description "Test tool description"
      end

      expect(test_tool.description).to eq("Test tool description")
    end
  end

  describe '.params' do
    it 'sets params schema' do
      test_tool = Class.new(described_class) do
        description "Test tool"
        params do
          string :command, description: "A command"
        end
      end

      expect(test_tool.parameters).to eq({
        command: { type: 'string', description: "A command" }
      })
    end
  end

  describe '#schema' do
    it 'generates OpenAI-compatible JSON Schema' do
      test_tool = Class.new(described_class) do
        description "Test tool"
        params do
          string :command, description: "A command"
        end
      end

      tool_instance = test_tool.new
      schema = tool_instance.schema

      expect(schema[:type]).to eq('function')
      expect(schema[:function][:description]).to eq('Test tool')
      expect(schema[:function][:parameters][:type]).to eq('object')
      expect(schema[:function][:parameters][:properties]).to eq({
        command: { type: 'string', description: "A command" }
      })
    end
  end

  describe '#execute' do
    it 'calls subclass execute method' do
      test_tool = Class.new(described_class) do
        description "Test tool"

        def execute(command:)
          { result: command }
        end
      end

      tool_instance = test_tool.new
      expect(tool_instance.execute(command: 'test')).to eq({ result: 'test' })
    end
  end
end

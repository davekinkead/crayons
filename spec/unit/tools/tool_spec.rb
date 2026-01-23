# frozen_string_literal: true

require_relative "../../../lib/tool"

RSpec.describe Crayons::Tool do
  describe "interface" do
    it "has a name attribute" do
      tool_class = Class.new(described_class) do
        def name = "test_tool"
      end

      expect(tool_class.new.name).to eq("test_tool")
    end

    it "has a description attribute" do
      tool_class = Class.new(described_class) do
        def description = "A test tool"
      end

      expect(tool_class.new.description).to eq("A test tool")
    end

    it "has a params attribute" do
      tool_class = Class.new(described_class) do
        def params = []
      end

      expect(tool_class.new.params).to eq([])
    end
  end

  describe "#call" do
    it "must be implemented by subclasses" do
      tool_class = Class.new(described_class)

      tool = tool_class.new

      expect { tool.call }.to raise_error(NotImplementedError)
    end
  end

  describe "return value" do
    it "returns a hash with success and result keys" do
      tool_class = Class.new(described_class) do
        def name = "test_tool"
        def description = "A test tool"
        def params = []

        def call(_input = nil)
          { success: true, result: "test output" }
        end
      end

      result = tool_class.new.call

      expect(result).to have_key(:success)
      expect(result).to have_key(:result)
      expect(result[:success]).to be true
      expect(result[:result]).to eq("test output")
    end
  end
end

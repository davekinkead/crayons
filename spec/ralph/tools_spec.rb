# frozen_string_literal: true
require "spec_helper"
require_relative "../../lib/ralph"

RSpec.describe Ralph::Tools do
  describe ".register" do
    it "registers a tool class" do
      tool_class = Class.new(Ralph::Tool) do
        description "Test tool"
        params do
          string :input, description: "Test input"
        end
        def execute(input:); end
      end

      Ralph::Tools.register(:test_tool, tool_class)
      expect(Ralph::Tools.get(:test_tool)).to eq(tool_class)
    end
  end

  describe ".get" do
    it "returns registered tool class" do
      tool_class = Class.new(Ralph::Tool) do
        description "Another test tool"
        params do
          string :value, description: "Test value"
        end
        def execute(value:); end
      end

      Ralph::Tools.register(:another_tool, tool_class)
      expect(Ralph::Tools.get(:another_tool)).to eq(tool_class)
    end

    it "returns nil for unregistered tool" do
      expect(Ralph::Tools.get(:nonexistent)).to be_nil
    end
  end
end


# frozen_string_literal: true
require "spec_helper"
require_relative "../../lib/crayons"

RSpec.describe Crayons::Tool do
  describe "#name" do
    it "returns lowercase tool name" do
      tool = Crayons::HaikuTool.new
      expect(tool.name).to eq("haiku")
    end
  end

  describe "#description" do
    it "returns tool description" do
      tool = Crayons::HaikuTool.new
      expect(tool.description).to eq("Generate a haiku on a given topic")
    end
  end

  describe "#parameters" do
    it "returns tool parameters" do
      tool = Crayons::HaikuTool.new
      expect(tool.parameters).to eq({
        topic: { type: "string", description: "The topic for the haiku" }
      })
    end
  end

  describe "#execute" do
    it "calls subclass execute method" do
      test_tool = Class.new(described_class) do
        description "Test tool"
        params do
          string :command, description: "A command"
        end

        def execute(command:)
          { result: command }
        end
      end

      tool_instance = test_tool.new
      expect(tool_instance.execute(command: "test")).to eq({ result: "test" })
    end
  end
end

# frozen_string_literal: true

require_relative "../../../lib/tools"

RSpec.describe Crayons::Tools::Batch do
  describe "#name" do
    it "returns 'batch'" do
      expect(subject.name).to eq("batch")
    end
  end

  describe "#description" do
    it "returns a description of the tool" do
      expect(subject.description).to eq("Execute multiple tools in a single call")
    end
  end

  describe "#params" do
    it "returns parameter definitions" do
      expect(subject.params).to be_an(Array)
      expect(subject.params.length).to eq(1)

      tools_param = subject.params.first
      expect(tools_param[:name]).to eq("tools")
      expect(tools_param[:description]).to eq("Array of tool calls with tool name and input")
      expect(tools_param[:required]).to be true
    end
  end

  describe "#call validation" do
    it "returns error when 'tools' key is missing" do
      result = subject.call({})

      expect(result[:success]).to be true
      expect(result[:result]).to be_an(Array)
      expect(result[:result].length).to eq(1)
      expect(result[:result].first[:success]).to be false
      expect(result[:result].first[:result]).to include("tools")
    end

    it "returns error when input is not an array" do
      result = subject.call(tools: "not an array")

      expect(result[:success]).to be true
      expect(result[:result]).to be_an(Array)
      expect(result[:result].length).to eq(1)
      expect(result[:result].first[:success]).to be false
      expect(result[:result].first[:result]).to include("Array")
    end

    it "returns error when tool call format is invalid (missing tool key)" do
      result = subject.call(tools: [{ input: {} }])

      expect(result[:success]).to be true
      expect(result[:result]).to be_an(Array)
      expect(result[:result].length).to eq(1)
      expect(result[:result].first[:success]).to be false
      expect(result[:result].first[:result]).to include("tool")
    end

    it "returns error when tool call format is invalid (missing input key)" do
      result = subject.call(tools: [{ tool: :haiku }])

      expect(result[:success]).to be true
      expect(result[:result]).to be_an(Array)
      expect(result[:result].length).to eq(1)
      expect(result[:result].first[:success]).to be false
      expect(result[:result].first[:result]).to include("input")
    end

    it "returns error for invalid tool name" do
      result = subject.call(tools: [{ tool: :nonexistent_tool, input: {} }])

      expect(result[:success]).to be true
      expect(result[:result]).to be_an(Array)
      expect(result[:result].length).to eq(1)
      expect(result[:result].first[:success]).to be false
      expect(result[:result].first[:result]).to start_with("Error: nonexistent_tool")
    end
  end
end

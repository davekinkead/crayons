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

  describe "#call" do
    context "success cases" do
      it "executes multiple tools successfully" do
        input = {
          tools: [
            { tool: :haiku, input: {} },
            { tool: :haiku, input: {} }
          ]
        }

        result = subject.call(input)

        expect(result[:success]).to be true
        expect(result[:result]).to be_an(Array)
        expect(result[:result].length).to eq(2)
        result[:result].each do |tool_result|
          expect(tool_result[:success]).to be true
          expect(tool_result[:result]).to be_a(String)
        end
      end

      it "executes a single tool" do
        input = {
          tools: [
            { tool: :haiku, input: {} }
          ]
        }

        result = subject.call(input)

        expect(result[:success]).to be true
        expect(result[:result]).to be_an(Array)
        expect(result[:result].length).to eq(1)
        expect(result[:result].first[:success]).to be true
      end

      it "handles empty tools array" do
        result = subject.call(tools: [])

        expect(result[:success]).to be true
        expect(result[:result]).to be_an(Array)
        expect(result[:result]).to be_empty
      end

      it "returns results in input order" do
        input = {
          tools: [
            { tool: :haiku, input: {} },
            { tool: :haiku, input: {} },
            { tool: :haiku, input: {} }
          ]
        }

        result = subject.call(input)

        expect(result[:result].length).to eq(3)
        expect(result[:result][0][:success]).to be true
        expect(result[:result][1][:success]).to be true
        expect(result[:result][2][:success]).to be true
      end

      it "supports both symbol and string tool names" do
        input = {
          tools: [
            { tool: :haiku, input: {} },
            { tool: "haiku", input: {} }
          ]
        }

        result = subject.call(input)

        expect(result[:success]).to be true
        expect(result[:result].length).to eq(2)
        expect(result[:result].all? { |r| r[:success] }).to be true
      end
    end

    context "support for string keys in input" do
      it "supports string 'tools' key" do
        input = {
          "tools" => [
            { tool: :haiku, input: {} }
          ]
        }

        result = subject.call(input)

        expect(result[:success]).to be true
        expect(result[:result].length).to eq(1)
        expect(result[:result].first[:success]).to be true
      end

      it "supports string 'tool' and 'input' keys in tool calls" do
        input = {
          tools: [
            { "tool" => "haiku", "input" => {} }
          ]
        }

        result = subject.call(input)

        expect(result[:success]).to be true
        expect(result[:result].length).to eq(1)
        expect(result[:result].first[:success]).to be true
      end
    end

    context "error handling" do
      it "continues execution when one tool fails" do
        input = {
          tools: [
            { tool: :haiku, input: {} },
            { tool: :nonexistent_tool, input: {} },
            { tool: :haiku, input: {} }
          ]
        }

        result = subject.call(input)

        expect(result[:success]).to be true
        expect(result[:result].length).to eq(3)
        expect(result[:result][0][:success]).to be true
        expect(result[:result][1][:success]).to be false
        expect(result[:result][2][:success]).to be true
      end
    end

    context "validation" do
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
end

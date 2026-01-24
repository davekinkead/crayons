# frozen_string_literal: true

require_relative "../../lib/tools"

RSpec.describe "Batch tool concurrent execution" do
  describe "#call success cases" do
    subject { Crayons::Tools::Batch.new }

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

  describe "#call string key support" do
    subject { Crayons::Tools::Batch.new }

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

  describe "#call error handling" do
    subject { Crayons::Tools::Batch.new }

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

  describe "#call concurrent execution" do
    subject { Crayons::Tools::Batch.new }

    it "executes multiple bash sleep commands concurrently" do
      input = {
        tools: [
          { tool: :bash, input: { command: "sleep 0.1", timeout: 10 } },
          { tool: :bash, input: { command: "sleep 0.1", timeout: 10 } },
          { tool: :bash, input: { command: "sleep 0.1", timeout: 10 } }
        ]
      }

      start_time = Time.now
      result = subject.call(input)
      end_time = Time.now

      expect(result[:success]).to be true
      expect(result[:result].length).to eq(3)
      result[:result].each do |tool_result|
        expect(tool_result[:success]).to be true
      end

      # Should take ~0.1s total if concurrent, not ~0.3s
      expect(end_time - start_time).to be < 0.25
    end

    it "returns results in input order even with concurrent execution" do
      input = {
        tools: [
          { tool: :haiku, input: {} },
          { tool: :haiku, input: {} },
          { tool: :haiku, input: {} }
        ]
      }

      result = subject.call(input)

      expect(result[:result].length).to eq(3)
      haiku_content = Crayons::Tools::Haiku::HAIKU.strip
      expect(result[:result][0][:result]).to eq(haiku_content)
      expect(result[:result][1][:result]).to eq(haiku_content)
      expect(result[:result][2][:result]).to eq(haiku_content)
    end

    it "handles errors in concurrent execution without stopping other tools" do
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
end

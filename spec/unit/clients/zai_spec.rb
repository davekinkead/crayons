# frozen_string_literal: true

require_relative "../../../lib/services/zai"
require_relative "../../../lib/message"
require_relative "../../../lib/logger"

RSpec.describe Crayons::Services::Zai do
  let(:api_key) { "test-api-key" }
  let(:base_url) { "https://api.test.com" }
  let(:model) { "test-model" }
  let(:mock_http_client) { instance_double(Crayons::Services::HTTP) }

  let(:system) { "You are a helpful assistant" }
  let(:messages) { [Crayons::Message.new(role: :user, content: "test message")] }
  let(:tools) { [] }

  let(:api_response) do
    {
      "choices" => [
        {
          "message" => {
            "role" => "assistant",
            "content" => "test response",
            "tool_calls" => nil
          },
          "finish_reason" => "stop"
        }
      ]
    }
  end

  subject { described_class.new(api_key: api_key, url: base_url, model: model) }

  before do
    allow(Crayons::Services::HTTP).to receive(:new).and_return(mock_http_client)
    allow(mock_http_client).to receive(:post).and_return(api_response)
  end

  describe "#initialize" do
    it "stores api_key" do
      expect(subject.instance_variable_get(:@api_key)).to eq(api_key)
    end

    it "stores base_url" do
      expect(subject.instance_variable_get(:@base_url)).to eq(base_url)
    end

    it "stores model" do
      expect(subject.instance_variable_get(:@model)).to eq(model)
    end

    context "with default values" do
      subject { described_class.new }

      it "uses default base_url" do
        expect(subject.instance_variable_get(:@base_url)).to eq("https://api.z.ai/api/coding/paas/v4")
      end

      it "uses default model" do
        expect(subject.instance_variable_get(:@model)).to eq("GLM-4.7")
      end
    end
  end

  describe "#chat" do
    it "prepends system message to messages" do
      expected_messages = [
        { role: "system", content: system },
        { role: "user", content: "test message" }
      ]

      expect(mock_http_client).to receive(:post)
        .with("#{base_url}/chat/completions", hash_including(model: model, messages: expected_messages, tools: []))
        .and_return(api_response)

      subject.chat(system: system, messages: messages, tools: tools)
    end

    it "converts tools to schema format" do
      test_tool = double(name: "test_tool", description: "A test tool", params: [{ name: "param1", description: "A parameter", required: true }])
      tools = [test_tool]

      expected_tools = [
        {
          type: "function",
          function: {
            name: "test_tool",
            description: "A test tool",
            parameters: {
              type: "object",
              properties: { param1: { type: "string", description: "A parameter" } },
              required: []
            }
          }
        }
      ]

      expect(mock_http_client).to receive(:post)
        .with("#{base_url}/chat/completions", hash_including(model: model, tools: expected_tools))
        .and_return(api_response)

      subject.chat(system: system, messages: messages, tools: tools)
    end

    it "includes tool_call_id if present in message" do
      messages_with_id = [Crayons::Message.new(role: :tool, content: "result", tool_call_id: "call_123")]

      expect(mock_http_client).to receive(:post)
        .with("#{base_url}/chat/completions", hash_including(model: model, tools: []))
        .and_return(api_response)

      subject.chat(system: system, messages: messages_with_id, tools: tools)
    end

    it "includes tool_calls if present in message" do
      messages_with_calls = [Crayons::Message.new(role: :assistant, content: nil, tool_calls: [{ id: "call_123", function: { name: "test", arguments: "{}" } }])]

      expect(mock_http_client).to receive(:post)
        .with("#{base_url}/chat/completions", hash_including(model: model, tools: []))
        .and_return(api_response)

      subject.chat(system: system, messages: messages_with_calls, tools: tools)
    end

    it "returns a Message object with parsed response" do
      result = subject.chat(system: system, messages: messages, tools: tools)

      expect(result).to be_a(Crayons::Message)
      expect(result.role).to eq(:assistant)
      expect(result.content).to eq("test response")
      expect(result.complete?).to be true
    end

    it "sets complete to true when finish_reason is stop" do
      result = subject.chat(system: system, messages: messages, tools: tools)

      expect(result.complete?).to be true
    end

    it "sets complete to false when finish_reason is not stop" do
      api_response["choices"][0]["finish_reason"] = "tool_calls"

      result = subject.chat(system: system, messages: messages, tools: tools)

      expect(result.complete?).to be false
    end

    it "includes tool_calls in response if present" do
      api_response["choices"][0]["message"]["tool_calls"] = [{
        "function" => { "name" => "test_tool", "arguments" => "{}" },
        "id" => "call_123",
        "type" => "function",
        "index" => 0
      }]

      result = subject.chat(system: system, messages: messages, tools: tools)

      expect(result.tool_call?).to be true
      expect(result.tool_calls).to eq([{
        function: { name: "test_tool", arguments: "{}" },
        id: "call_123",
        type: "function",
        index: 0
      }])
    end
  end

  describe ".convert_messages_to_api_format" do
    it "converts messages to API format with role and content" do
      message = Crayons::Message.new(role: :user, content: "test")

      result = described_class.convert_messages_to_api_format([message])

      expect(result).to eq([{ role: "user", content: "test" }])
    end

    it "includes tool_calls when present" do
      message = Crayons::Message.new(role: :assistant, content: nil, tool_calls: [{ id: "call_123" }])

      result = described_class.convert_messages_to_api_format([message])

      expect(result.first[:tool_calls]).to eq([{ id: "call_123" }])
    end

    it "includes tool_call_id when present" do
      message = Crayons::Message.new(role: :tool, content: "result", tool_call_id: "call_123")

      result = described_class.convert_messages_to_api_format([message])

      expect(result.first[:tool_call_id]).to eq("call_123")
    end

    it "handles messages without content" do
      message = Crayons::Message.new(role: :assistant, content: nil)

      result = described_class.convert_messages_to_api_format([message])

      expect(result.first).not_to have_key(:content)
    end
  end

  describe ".convert_tools_to_schemas" do
    it "converts tools to function schema format" do
      tool = double(name: "test_tool", description: "A test tool", params: [{ name: "param1", description: "A parameter", required: true }])

      result = described_class.convert_tools_to_schemas([tool])

      expect(result).to eq([
        {
          type: "function",
          function: {
            name: "test_tool",
            description: "A test tool",
            parameters: {
              type: "object",
              properties: { param1: { type: "string", description: "A parameter" } },
              required: []
            }
          }
        }
      ])
    end

    it "handles tools without parameters" do
      tool = double(name: "test_tool", description: "A test tool", params: [])

      result = described_class.convert_tools_to_schemas([tool])

      expect(result.first[:function][:parameters]).to eq({ type: "object", properties: {}, required: [] })
    end
  end

  describe ".parse_response" do
    it "parses response and creates Message object" do
      result = described_class.parse_response(api_response)

      expect(result).to be_a(Crayons::Message)
      expect(result.role).to eq(:assistant)
      expect(result.content).to eq("test response")
      expect(result.complete?).to be true
    end

    it "handles tool_calls in response" do
      api_response["choices"][0]["message"]["tool_calls"] = [{
        "function" => { "name" => "test_tool", "arguments" => "{}" },
        "id" => "call_123",
        "type" => "function",
        "index" => 0
      }]

      result = described_class.parse_response(api_response)

      expect(result.tool_calls).to eq([{
        function: { name: "test_tool", arguments: "{}" },
        id: "call_123",
        type: "function",
        index: 0
      }])
      expect(result.tool_call?).to be true
    end
  end
end

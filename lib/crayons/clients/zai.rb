# frozen_string_literal: true
require_relative "base"
require_relative "http"
require_relative "../message"
require_relative "../logger"

module Crayons
  module Clients
    class Zai < Base
      def initialize(api_key: ENV.fetch("ZAI_API_KEY", nil), url: nil, model: nil)
        @api_key = api_key
        @base_url = url || "https://api.z.ai/api/coding/paas/v4"
        @model = model || "GLM-4.7"
        @http_client = HTTP.new(api_key: @api_key, base_url: @base_url)
        @logger = Crayons::Logger.instance
        @logger.info("ZaiClient", "Initialized with base_url: #{@base_url}, model: #{@model}")
      end

      def chat(system:, messages:, tools:)
        messages_with_system = [Message.new(role: :system, content: system)] + messages
        payload = {
          model: @model,
          messages: self.class.convert_messages_to_api_format(messages_with_system),
          tools: self.class.convert_tools_to_schemas(tools)
        }

        @logger.debug("ZaiClient", "Sending #{messages_with_system.length} messages with #{payload[:tools]&.length || 0} tools to #{@base_url}/chat/completions")

        response = @http_client.post("#{@base_url}/chat/completions", payload)

        self.class.parse_response(response)
      end

      class << self
        def convert_messages_to_api_format(messages)
          messages.map do |msg|
            api_msg = { role: msg.role.to_s }
            api_msg[:content] = msg.content if msg.content
            api_msg[:tool_calls] = msg.tool_calls if msg.tool_call?
            api_msg[:tool_call_id] = msg.tool_call_id if msg.tool_call_id
            api_msg
          end
        end

        def convert_tools_to_schemas(tools)
          tools.map do |tool|
            {
              type: "function",
              function: {
                name: tool.name,
                description: tool.description,
                parameters: {
                  type: "object",
                  properties: tool.parameters || {},
                  required: []
                }
              }
            }
          end
        end

        def parse_response(response)
          choice = response["choices"].first
          message_data = choice["message"]
          finish_reason = choice["finish_reason"]

          Message.new(
            role: message_data["role"].to_sym,
            content: message_data["content"],
            complete: finish_reason == "stop",
            tool_calls: message_data["tool_calls"]
          )
        end
      end
    end
  end
end

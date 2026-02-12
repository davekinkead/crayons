# frozen_string_literal: true
require_relative "base"
require_relative "http"
require_relative "../message"
require_relative "../logger"
require_relative "../utils"

module Crayons
  module Services
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

        # Log summary format: model=X, messages=Y, tools=Z
        summary_parts = []
        summary_parts << "model=#{@model}" if @model
        summary_parts << "messages=#{messages_with_system.length}"
        summary_parts << "tools=#{payload[:tools]&.length || 0}"
        @logger.debug("ZaiClient", summary_parts.join(", "))

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
                  properties: convert_params_to_hash(tool.params),
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
            tool_calls: convert_tool_calls_to_symbols(message_data["tool_calls"])
          )
        end

        def convert_tool_calls_to_symbols(tool_calls)
          return nil unless tool_calls

          tool_calls.map { |tool_call| Utils.symbolize_keys(tool_call) }
        end

        def convert_params_to_hash(params)
          params.each_with_object({}) do |param, hash|
            hash[param[:name].to_sym] = {
              type: "string",
              description: param[:description]
            }
          end
        end
      end
    end
  end
end

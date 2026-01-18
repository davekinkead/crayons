require_relative 'http'
require_relative '../message'

module Ralph
  module Clients
    class Zai
      def initialize(env: ENV, tools: [])
        @env = env
        @api_key = @env['ZAI_API_KEY'] || @env['OPENAI_API_KEY']
        @base_url = @env['OPENAI_BASE_URL']
        @model = @env['OPENAI_MODEL']
        @tools = tools
        @http_client = HTTP.new(api_key: @api_key, base_url: @base_url)
        puts "[ZaiClient] Initialized with base_url: #{@base_url}, model: #{@model}, tools: #{@tools.map { |t| t.name.split('::').last }.join(', ')}"
      end

      def chat(messages)
        payload = {
          model: @model,
          messages: convert_messages_to_api_format(messages),
          tools: convert_tools_to_schemas
        }

        puts "[ZaiClient] Sending #{messages.length} messages with #{payload[:tools]&.length || 0} tools to #{@base_url}/chat/completions"

        response = @http_client.post("#{@base_url}/chat/completions", payload)

        parse_response(response)
      end

      private

      def convert_messages_to_api_format(messages)
        messages.map do |msg|
          api_msg = { role: msg.role.to_s }
          api_msg[:content] = msg.content if msg.content
          api_msg[:tool_calls] = msg.tool_calls if msg.tool_call?
          api_msg[:tool_call_id] = msg.tool_call_id if msg.tool_call_id
          api_msg
        end
      end

      def convert_tools_to_schemas
        @tools.map do |tool_class|
          tool = tool_class.new
          {
            type: 'function',
            function: {
              name: tool.name,
              description: tool.description,
              parameters: {
                type: 'object',
                properties: tool.parameters || {},
                required: []
              }
            }
          }
        end
      end

      def parse_response(response)
        choice = response['choices'].first
        message_data = choice['message']

        Message.new(
          role: message_data['role'].to_sym,
          content: message_data['content'],
          tool_calls: message_data['tool_calls']
        )
      end
    end
  end
end


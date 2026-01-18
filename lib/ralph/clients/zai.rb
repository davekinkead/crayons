require_relative 'http'
require_relative '../message'

module Ralph
  module Clients
    class Zai
      def initialize(env: ENV)
        @env = env
        @api_key = @env['ZAI_API_KEY'] || @env['OPENAI_API_KEY']
        @base_url = @env['OPENAI_BASE_URL']
        @model = @env['OPENAI_MODEL']
        @http_client = HTTP.new(api_key: @api_key, base_url: @base_url)
      end

      def chat(messages)
        payload = {
          model: @model,
          messages: convert_messages_to_api_format(messages)
        }

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


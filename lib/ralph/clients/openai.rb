require 'openai'

module Ralph
  module Clients
    class OpenAI
      def self.tools(tool_list)
        tool_list.map do |tool_name|
          tool_class = find_tool_class(tool_name)
          tool_class&.schema
        end.compact
      end

      def self.find_tool_class(tool_name)
        ObjectSpace.each_object(Class).find do |klass|
          klass < Ralph::Tool && klass.name&.downcase&.end_with?("::#{tool_name.downcase}")
        end
      end

      def initialize(api_key: nil, base_url: nil, model: nil)
        @client = ::OpenAI::Client.new(
          api_key: api_key || ENV['ZAI_API_KEY'] || ENV['OPENAI_API_KEY'],
          base_url: base_url || ENV['OPENAI_BASE_URL'] || 'https://api.openai.com/v1'
        )
        @model = model || ENV['OPENAI_MODEL']
      end

      def chat(messages:, tools: nil)
        params = { model: @model, messages: messages }
        params[:tools] = tools if tools

        response = @client.chat.completions.create(**params)

        response.choices.first.message
      end
    end
  end
end

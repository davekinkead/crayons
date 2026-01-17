require 'openai'

module Ralph
  module Clients
    class OpenAI
      def initialize(api_key: nil, base_url: nil, model: nil)
        @client = ::OpenAI::Client.new(
          api_key: api_key || ENV['ZAI_API_KEY'] || ENV['OPENAI_API_KEY'],
          base_url: base_url ||ENV['OPENAI_BASE_URL'] || 'https://api.openai.com/v1'
        )
        @model = model || ENV['OPENAI_MODEL']
      end

      def chat(messages:, tools: nil)
        params = { model: @model, messages: }
        params[:tools] = tools if tools

        response = @client.chat.completions.create(**params)

        response.choices.first.message
      end
    end
  end
end

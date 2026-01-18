module Ralph
  module Clients
    class Zai
      def initialize
        @context = RubyLLM.context do |config|
          config.openai_api_key = ENV['ZAI_API_KEY'] || ENV['OPENAI_API_KEY']
          config.openai_api_base = ENV['OPENAI_BASE_URL']
          config.default_model = ENV['OPENAI_MODEL'] if ENV['OPENAI_MODEL']
          config.log_level = :debug
          config.log_stream_debug = true
        end
      end

      def chat
        if ENV['OPENAI_MODEL']
          @context.chat(model: ENV['OPENAI_MODEL'], provider: :openai, assume_model_exists: true)
        else
          @context.chat
        end
      end
    end
  end
end

module Ralph
  class Client
    def initialize
      @context = RubyLLM.context do |config|
        config.openai_api_key = ENV['ZAI_API_KEY'] || ENV['OPENAI_API_KEY']
        config.openai_api_base = ENV['OPENAI_BASE_URL']
        config.default_model = ENV['OPENAI_MODEL'] if ENV['OPENAI_MODEL']
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

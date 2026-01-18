module Ralph
  class Client
    def self.new(tools: [])
      client_class = ENV['RALPH_CLIENT']&.to_sym || :zai
      client_name = client_class.to_s.split('_').map(&:capitalize).join
      client_class_const = const_get("Ralph::Clients::#{client_name}")
      client_class_const.new(tools: tools)
    rescue NameError
      Clients::Zai.new(tools: tools)
    end
  end
end

require_relative 'clients/zai'

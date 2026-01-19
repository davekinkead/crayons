module Ralph
  class Client
    def self.new(api_key: nil, url: nil, model: nil)
      client_class = ENV['RALPH_CLIENT']&.to_sym || :zai
      client_name = client_class.to_s.split('_').map(&:capitalize).join
      client_class_const = const_get("Ralph::Clients::#{client_name}")
      client_class_const.new(api_key: api_key, url: url, model: model)
    rescue NameError
      Clients::Zai.new(api_key: api_key, url: url, model: model)
    end
  end
end

require_relative 'clients/zai'

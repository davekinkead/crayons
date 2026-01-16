require 'net/http'
require 'json'
require 'uri'

module Ralph
  module Clients
    class OpenAI
      def initialize(api_key: ENV['ZAI_API_KEY'] || ENV['OPENAI_API_KEY'], base_url: ENV['OPENAI_BASE_URL'] || 'https://api.openai.com/v1', model: ENV['OPENAI_MODEL'])
        @api_key = api_key
        @base_url = base_url
        @model = model
      end

      def chat(messages:)
        uri = URI("#{@base_url}/chat/completions")
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = 'application/json'
        request.body = { model: @model, messages: }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        handle_response(response)
      end

      private

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          parse_response(response.body)
        when Net::HTTPUnauthorized
          raise Error, 'Invalid API key'
        when Net::HTTPTooManyRequests
          raise Error, 'Rate limit exceeded'
        else
          raise Error, "API error: #{response.code} #{response.message}"
        end
      end

      def parse_response(body)
        data = JSON.parse(body)
        data.dig('choices', 0, 'message', 'content')
      end
    end
  end
end

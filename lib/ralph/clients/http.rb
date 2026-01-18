require 'httpx'
require 'json'

module Ralph
  module Clients
    class HTTP
      NetworkError = Class.new(StandardError)
      APIError = Class.new(StandardError)
      ResponseError = Class.new(StandardError)

      def initialize(api_key:, base_url:)
        @api_key = api_key
        @base_url = base_url
      end

      def post(url, payload)
        response = HTTPX.post(
          url,
          headers: {
            'Authorization' => "Bearer #{@api_key}",
            'Content-Type' => 'application/json'
          },
          body: payload.to_json
        )

        handle_response(response)
      rescue HTTPX::TimeoutError, HTTPX::ConnectionError, Errno::ECONNREFUSED => e
        raise NetworkError, "Network error: #{e.message}"
      end

      private

      def handle_response(response)
        status = response.status

        if status >= 400
          raise APIError, "API error (#{status}): #{response.body.to_s}"
        end

        JSON.parse(response.body.to_s)
      rescue JSON::ParserError => e
        raise ResponseError, "Invalid JSON response: #{e.message}"
      end
    end
  end
end

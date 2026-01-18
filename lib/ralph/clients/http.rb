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
        puts "[HTTP] POST #{url}"
        puts "[HTTP] Payload: #{payload.to_json[0..200]}..." if payload.to_json.length > 200

        response = HTTPX.post(
          url,
          headers: {
            'Authorization': "Bearer #{@api_key}",
            'Content-Type': 'application/json'
          },
          body: payload.to_json,
          timeout: { connect_timeout: 10, operation_timeout: 60 }
        )

        handle_response(response)
      rescue HTTPX::TimeoutError, HTTPX::ConnectionError, Errno::ECONNREFUSED => e
        puts "[HTTP] Network error: #{e.message}"
        raise NetworkError, "Network error: #{e.message}"
      end

      private

      def handle_response(response)
        status = response.status
        body = response.body.to_s

        puts "[HTTP] Response status: #{status}"

        if status >= 400
          puts "[HTTP] Error body: #{body[0..500]}..."
          raise APIError, "API error (#{status}): #{body}"
        end

        JSON.parse(body)
      rescue JSON::ParserError => e
        puts "[HTTP] JSON parse error: #{e.message}"
        raise ResponseError, "Invalid JSON response: #{e.message}"
      end
    end
  end
end

require 'httpx'
require 'json'
require_relative '../logger'

module Ralph
  module Clients
    class HTTP
      NetworkError = Class.new(StandardError)
      APIError = Class.new(StandardError)
      ResponseError = Class.new(StandardError)

      def initialize(api_key:, base_url:)
        @api_key = api_key
        @base_url = base_url
        @logger = Ralph::Logger.instance
      end

      def post(url, payload)
        @logger.debug('HTTP', "POST #{url}")
        @logger.debug('HTTP', "Payload: #{payload.to_json}...")

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
        @logger.error('HTTP', "Network error: #{e.message}")
        raise NetworkError, "Network error: #{e.message}"
      end

      private

      def handle_response(response)
        status = response.status
        body = response.body.to_s

        @logger.debug('HTTP', "Response status: #{status}")

        if status >= 400
          @logger.error('HTTP', "Error body: #{body[0..500]}...")
          raise APIError, "API error (#{status}): #{body}"
        end

        JSON.parse(body)
      rescue JSON::ParserError => e
        @logger.error('HTTP', "JSON parse error: #{e.message}")
        raise ResponseError, "Invalid JSON response: #{e.message}"
      end
    end
  end
end

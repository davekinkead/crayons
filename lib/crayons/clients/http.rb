# frozen_string_literal: true
require "async"
require "httpx"
require "json"
require_relative "../logger"

module Crayons
  module Clients
    class HTTP
      NetworkError = Class.new(StandardError)
      APIError = Class.new(StandardError)
      ResponseError = Class.new(StandardError)

      def initialize(api_key:, base_url:)
        @api_key = api_key
        @base_url = base_url
        @logger = Crayons::Logger.instance
      end

      def post(url, payload)
        @logger.debug("HTTP", "POST #{url}")
        @logger.debug("HTTP", format_payload_summary(payload))

        Async do
          response = HTTPX.post(
            url,
            headers: {
              Authorization: "Bearer #{@api_key}",
              "Content-Type": "application/json"
            },
            body: payload.to_json,
            timeout: { connect_timeout: 10, operation_timeout: 60 }
          )

          handle_response(response)
        end.wait
      rescue HTTPX::TimeoutError, HTTPX::ConnectionError, Errno::ECONNREFUSED => e
        @logger.error("HTTP", "Network error: #{e.message}")
        raise NetworkError, "Network error: #{e.message}"
      end

      private

      def format_payload_summary(payload)
        summary_parts = []

        # Add model if present
        summary_parts << "model=#{payload[:model]}" if payload[:model]

        # Add messages count if present
        summary_parts << "messages=#{payload[:messages].length}" if payload[:messages]

        # Add tools count if present
        summary_parts << "tools=#{payload[:tools].length}" if payload[:tools]

        summary_parts.join(", ")
      end

      def handle_response(response)
        # Check if response is an HTTPX::ErrorResponse (doesn't have status method)
        if response.is_a?(HTTPX::ErrorResponse)
          error_message = extract_error_message(response)
          @logger.error("HTTP", "ErrorResponse: #{error_message}")
          raise NetworkError, "Network error: #{error_message}"
        end

        status = response.status
        body = response.body.to_s

        @logger.debug("HTTP", "Response status: #{status}")

        if status >= 400
          @logger.error("HTTP", "Error body: #{body[0..500]}...")
          raise APIError, "API error (#{status}): #{body}"
        end

        JSON.parse(body)
      rescue JSON::ParserError => e
        @logger.error("HTTP", "JSON parse error: #{e.message}")
        raise ResponseError, "Invalid JSON response: #{e.message}"
      rescue APIError, ResponseError
        raise
      rescue StandardError => e
        @logger.error("HTTP", "Response handling error: #{e.message}")
        raise NetworkError, "Network error: #{e.message}"
      end

      def extract_error_message(error_response)
        # HTTPX::ErrorResponse has an error attribute with the wrapped exception
        if error_response.respond_to?(:error)
          error = error_response.error
          return error.message if error.respond_to?(:message)
        end

        # Fallback to to_s if error method doesn't work
        error_response.to_s
      end
    end
  end
end

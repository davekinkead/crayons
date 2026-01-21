# frozen_string_literal: true
require "async"
require "async/http/internet"
require "json"
require_relative "../logger"
require_relative "../version"

module Crayons
  module Clients
    class HTTP
      ClientError = Class.new(StandardError)

      def initialize(api_key:, base_url:, http_client: Async::HTTP::Internet.new)
        @api_key = api_key
        @base_url = base_url
        @http_client = http_client
        @logger = Crayons::Logger.instance
      end

      def post(url, payload)
        @logger.debug("HTTP", "POST #{url}")
        @logger.debug("HTTP", format_payload_summary(payload))

        Sync do |task|
          task.annotate "Crayons::HTTP POST #{url}"

          response = @http_client.post(
            url,
            [
              ["authorization", "Bearer #{@api_key}"],
              ["content-type", "application/json"],
              ["user-agent", "opencode/#{Crayons::VERSION}"]
            ],
            payload.to_json
          )

          begin
            result = handle_response(response)
          ensure
            response&.close
          end

          result
        rescue Async::TimeoutError, Timeout::Error => e
          @logger.error("HTTP", "Request timeout: #{e.message}")
          raise ClientError, "Request timeout: #{e.message}"
        rescue Errno::ECONNREFUSED => e
          @logger.error("HTTP", "Connection refused: #{e.message}")
          raise ClientError, "Connection refused: #{e.message}"
        rescue StandardError => e
          @logger.error("HTTP", "Client error: #{e.message}")
          raise ClientError, e.message
        end
      end

      private

      def format_payload_summary(payload)
        summary_parts = []

        summary_parts << "model=#{payload[:model]}" if payload[:model]
        summary_parts << "messages=#{payload[:messages].length}" if payload[:messages]
        summary_parts << "tools=#{payload[:tools].length}" if payload[:tools]

        summary_parts.join(", ")
      end

      def handle_response(response)
        status = response.status
        body = response.read

        @logger.debug("HTTP", "Response status: #{status}")

        if status >= 400
          @logger.error("HTTP", "Error body: #{body[0..500]}...")
          raise ClientError, "API error (#{status}): #{body}"
        end

        JSON.parse(body)
      rescue JSON::ParserError => e
        @logger.error("HTTP", "JSON parse error: #{e.message}")
        raise ClientError, "Invalid JSON response: #{e.message}"
      rescue ClientError
        raise
      rescue StandardError => e
        @logger.error("HTTP", "Response handling error: #{e.message}")
        raise ClientError, "Network error: #{e.message}"
      end
    end
  end
end

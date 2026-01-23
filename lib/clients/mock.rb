# frozen_string_literal: true

require_relative "base"
require_relative "../message"

module Crayons
  module Clients
    class Mock < Base
      def initialize(response: nil)
        @response = response || "Mock response from agent"
      end

      def chat(system:, messages:, tools:)
        last_message = messages.last
        prompt = last_message&.content || ""

        Message.new(
          role: :assistant,
          content: generate_mock_response(prompt, tools),
          complete: true,
          tool_calls: nil
        )
      end

      private

      def generate_mock_response(prompt, tools)
        return @response if @response.is_a?(String)

        tool_names = tools.map(&:name).join(", ")
        "Mock agent received: \"#{prompt}\"\nAvailable tools: #{tool_names}\n\nThis is a mock response - no LLM API required."
      end
    end
  end
end

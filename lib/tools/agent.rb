# frozen_string_literal: true

require_relative "../tool"
require_relative "../agent"

module Crayons
  module Tools
    class AgentTool < Crayons::Tool
      attr_reader :agent_name

      def initialize(agent_name, client: nil)
        @agent_name = agent_name
        @agent = Crayons::Agent.new(agent_name, client: client)
      end

      def name = @agent.name

      def description = @agent.instance_variable_get(:@config)&.dig("description") || ""

      def params = []

      def call(input)
        prompt = input.to_s
        message = @agent.call(prompt)
        content = message.content || ""

        if content.start_with?("FAILURE:")
          { success: false, result: content.sub(/^FAILURE:\s*/, "").strip }
        elsif content.start_with?("SUCCESS:")
          { success: true, result: content.sub(/^SUCCESS:\s*/, "").strip }
        else
          { success: true, result: content }
        end
      rescue StandardError => e
        { success: false, result: e.message }
      end
    end
  end
end

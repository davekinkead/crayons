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

        { success: true, result: message.content || "" }
      rescue StandardError => e
        { success: false, result: e.message }
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../logger"

module Crayons
  class ExploreTool < Tool
    description "Explore the codebase to find relevant files all at once"

    params do
      string :problem, description: "Problem description or area of codebase to explore"
    end

    def initialize
      super
      @logger = Crayons::Logger.instance
    end

    def execute(problem:)
      return { error: "Problem description cannot be empty", success: false } if problem.nil? || problem.strip.empty?

      agent = Crayons::Agent.new("WILLIE")

      agent.call(problem)
    rescue StandardError => e
      error_message = e.message

      if error_message.include?("Agent file not found")
        @logger.warn("ExploreTool", "WILLIE agent file not found - explore tool is broken")
        available_agents = list_available_agents
        error_message += "\n\nAvailable agents: #{available_agents.join(', ')}"
      end

      { error: error_message, success: false }
    end

    private

    def list_available_agents
      agents_dir = File.join(File.dirname(__FILE__), "../../../agents")
      return [] unless Dir.exist?(agents_dir)

      Dir.glob("#{agents_dir}/*.md").map do |file|
        File.basename(file, ".md")
      end.sort
    end
  end
end

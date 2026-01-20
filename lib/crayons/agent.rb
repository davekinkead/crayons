# frozen_string_literal: true
require_relative "message"
require_relative "logger"

module Crayons
  class Agent
    DEFAULT_MAX_ITERATIONS = 20

    attr_reader :name, :description, :tools, :instructions, :max_iterations, :id, :messages

    def initialize(agent_name, client: nil)
      agent_file = File.join(File.dirname(__FILE__), "../../agents/#{agent_name}.md")
      raise "Agent file not found: #{agent_file}" unless File.exist?(agent_file)

      load_agent_config(agent_file)
      @tool_instances = @tools.map { |t| Crayons::Tools.get(t.to_sym)&.new }.compact
      @client = client || create_client_from_config
      @messages = []
      @id = "#{@name}:#{object_id}"
      @logger = Crayons::Logger.instance
    end

    def call(prompt)
      @logger.info(@id, "Starting agent execution")
      @messages = []
      @instructions += default_system_prompt

      iteration = 0
      loop do
        response = chat(iteration.zero? ? prompt : nil)
        iteration += 1

        if response.tool_call?
          response.tool_calls.each { |tool_call| execute_tool(tool_call) }
          next
        end

        if response.complete?
          @logger.info(@id, "Complete - #{response.content}")
          return response.content
        end

        break if iteration >= @max_iterations
      end

      @logger.warn(@id, "Max iterations reached")
      final_prompt = "You've reached the maximum number of turns without completing the task. Please explain why you couldn't complete it and what went wrong."
      final_response = chat(final_prompt)
      "FAILURE: Max iterations reached. #{final_response.content}"
    rescue StandardError => e
      @logger.error(@id, "Agent execution failed: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
      "FAILURE: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    def chat(prompt)
      @messages << Message.new(role: :user, content: prompt) if prompt
      response = @client.chat(system: @instructions, messages: @messages, tools: @tool_instances)
      @messages << response
      response
    end

    private

    def create_client_from_config
      client_type = @client_type || ENV["CRAYONS_CLIENT"] || :zai
      model = @model || ENV["ZAI_MODEL"] || "GLM-4.7"
      api_key = ENV.fetch("ZAI_API_KEY", nil)

      client_class_name = client_type.to_s.split("_").map(&:capitalize).join
      client_class = const_get("Crayons::Clients::#{client_class_name}")
      client_class.new(api_key:, model:)
    rescue NameError
      Crayons::Clients::Zai.new(api_key:, model:)
    end

    def execute_tool(tool_call)
      tool_name = tool_call["function"]["name"]
      tool_args = JSON.parse(tool_call["function"]["arguments"]).transform_keys(&:to_sym)

      @logger.debug(@id, "TOOL_CALL #{tool_name} #{tool_args}")

      tool_instance = @tool_instances.find { |t| t.name == tool_name }

      unless tool_instance
        @logger.warn(@id, "Tool not found: #{tool_name}")
        return
      end

      result = tool_instance.execute(**tool_args)

      @logger.debug(@id, "TOOL_RESPONSE #{tool_name} #{result}")

      @messages << Message.new(
        role: :tool,
        tool_call_id: tool_call["id"],
        content: result.to_json
      )
    end

    def load_agent_config(file_path)
      content = File.read(file_path)
      frontmatter, body = parse_frontmatter(content)

      @name = frontmatter["name"]
      @description = frontmatter["description"]
      @tools = Array(frontmatter["tools"])
      @instructions = body.strip
      @client_type = frontmatter["client"]
      @model = frontmatter["model"]

      @max_iterations = frontmatter["max_iterations"] || DEFAULT_MAX_ITERATIONS
      validate_max_iterations!
    end

    def validate_max_iterations!
      return if @max_iterations.is_a?(Integer) && @max_iterations.positive?
        raise "max_iterations must be a positive integer, got: #{@max_iterations.inspect}"
      
    end

    def parse_frontmatter(content)
      return [{}, content] unless content.start_with?("---")

      parts = content.split("---", 3)
      return [{}, content] if parts.length < 3

      frontmatter_content = parts[1]
      body = parts[2]

      begin
        require "yaml"
        [YAML.safe_load(frontmatter_content), body]
      rescue Psych::SyntaxError
        [{}, content]
      end
    end

    def default_system_prompt
      <<~PROMPT

        **CRITICAL**: Always return your response in this format:
        - "SUCCESS: {short summary}" when task is complete
        - "FAILURE: {detailed explanation}" when task cannot be completed
      PROMPT
    end
  end
end

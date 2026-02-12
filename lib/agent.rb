# frozen_string_literal: true

require "async"
require_relative "services/zai"
require_relative "logger"
require_relative "message"
require_relative "tools"
require_relative "utils"
require "yaml"
require "fileutils"
require "json"

module Crayons
  class Agent
    attr_reader :name

    def self.common_system_prompt
      <<~PROMPT
        ## CRITICAL

        When responding to a task, you MUST indicate the outcome by starting your response with either:
        - SUCCESS: [followed by your success message]
        - FAILURE: [followed by your failure message and explanation]

        Examples:
        SUCCESS: Code review passed with 2 minor suggestions
        FAILURE: Critical security vulnerability found in authentication logic
      PROMPT
    end

  def initialize(name, client: nil)
    @client = client || Crayons::Services::Zai.new
    @message_history = []
    @tools = []
    @logger = Crayons::Logger.instance
    load_agent_config(name)
  end

  def id
    "#{name.downcase}-#{object_id}"
  end

    def call(prompt)
      @logger.info(id, "PROMPT: #{prompt}")

      @message_history << Message.new(role: :user, content: prompt)

      loop do
        response = chat
        @message_history << response

        @logger.info(id, response.content) if response.content

        return response if response.complete?

        handle_tool_calls(response) if response.tool_call?
      end
    end

    def chat
      @client.chat(
        system: @system_prompt,
        messages: @message_history,
        tools: @tools
      )
    end

    private

    def load_agent_config(name)
      agent_file = File.expand_path("../agents/#{name.to_s.upcase}.md", __dir__)

      raise "Agent file not found" unless File.exist?(agent_file)

      content = File.read(agent_file)

      raise "Invalid agent file format: missing YAML front matter" unless content =~ /\A---(.*?)---/m
        yaml_content = Regexp.last_match(1)
        @config = YAML.safe_load(yaml_content)
        @name = @config["name"]
        @tools = load_tools(@config["tools"] || [])
        @system_prompt = "#{content.sub(/\A---.*?---\n?/m, '').strip}\n\n#{self.class.common_system_prompt}"
    end

    def load_tools(tool_names)
      tool_names.map { |tool_name| Crayons::Tools.new(tool_name.to_sym) }
    end

    def handle_tool_calls(response)
      Async do
        tasks = response.tool_calls.map do |tool_call|
          Async do
            tool_name = tool_call.dig(:function, :name).to_sym
            tool_args = JSON.parse(tool_call.dig(:function, :arguments) || "{}", symbolize_names: true)

            @logger.debug(id, "Tool: #{tool_name} #{tool_args}")

            tool = Crayons::Tools.new(tool_name)
            result = tool.call(tool_args)

            @logger.debug(id, "Tool Result: #{result[:success] ? 'SUCCESS' : 'FAILURE'} - #{result[:result]}")

            { tool_call: tool_call, result: result }
          rescue StandardError => e
            @logger.error(id, "Tool Error: #{e.message}")
            { tool_call: tool_call, result: { success: false, result: e.message } }
          end
        end

        tasks.each do |task|
          task_result = task.wait
          @message_history << Message.new(
            role: :tool,
            content: task_result[:result][:result].to_s,
            tool_call_id: task_result[:tool_call][:id]
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "clients/zai"
require_relative "message"
require_relative "tools"
require_relative "utils"
require "yaml"
require "fileutils"
require "json"

module Crayons
  class Agent
    attr_reader :name

  def initialize(name, client: nil)
    @client = client || Crayons::Clients::Zai.new
    @message_history = []
    @tools = []
    load_agent_config(name)
  end

    def call(prompt)
      @message_history << Message.new(role: :user, content: prompt)

      loop do
        response = chat
        @message_history << response

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
        @system_prompt = content.sub(/\A---.*?---\n?/m, "").strip
    end

    def load_tools(tool_names)
      tool_names.map { |tool_name| Crayons::Tools.new(tool_name.to_sym) }
    end

    def handle_tool_calls(response)
      response.tool_calls.each do |tool_call|
        tool_name = tool_call.dig(:function, :name).to_sym
        tool_args = JSON.parse(tool_call.dig(:function, :arguments) || "{}", symbolize_names: true)

        tool = Crayons::Tools.new(tool_name)
        result = tool.call(tool_args)

        @message_history << Message.new(
          role: :tool,
          content: result[:result].to_s,
          tool_call_id: tool_call[:id]
        )
      end
    end

    def format_response(message)
      if message.content
        "SUCCESS: #{message.content}"
      else
        "FAILURE: No response content received"
      end
    end
  end
end

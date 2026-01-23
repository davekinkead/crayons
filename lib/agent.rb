# frozen_string_literal: true

require_relative "clients/zai"
require_relative "message"
require "yaml"
require "fileutils"

module Crayons
  class Agent
    attr_reader :name

  def initialize(name, client: nil)
    @client = client || Crayons::Clients::Zai.new
    load_agent_config(name)
  end

    def call(prompt)
      message = Message.new(role: :user, content: prompt)

      response = chat(messages: [message])

      format_response(response)
    end

    def chat(messages:, tools: [])
      @client.chat(
        system: @system_prompt,
        messages: messages,
        tools: tools
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
        @system_prompt = content.sub(/\A---.*?---\n?/m, "").strip
      
        
      
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

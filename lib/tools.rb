# frozen_string_literal: true

require_relative "tool"
require_relative "errors"
require_relative "tools/agent"
require "yaml"

Dir[File.join(__dir__, "tools", "*.rb")].each { |file| require_relative file }

module Crayons
  module Tools
    def self.new(tool_name)
      agent_path = File.expand_path("../agents/#{tool_name.to_s.upcase}.md", __dir__)

      return AgentTool.new(tool_name) if agent_file_exists?(agent_path)

      load_tool_class(tool_name)
    rescue NameError
      raise Crayons::ToolNotFoundError, "Tool :#{tool_name} not found"
    end

    def self.agent_file_exists?(path)
      File.exist?(path)
    end

    def self.load_tool_class(tool_name)
      klass_name = tool_name.to_s.split("_").map(&:capitalize).join
      const_get(klass_name).new
    end

    private_class_method :agent_file_exists?, :load_tool_class
  end
end

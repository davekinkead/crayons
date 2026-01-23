# frozen_string_literal: true

require_relative "tool"
require_relative "errors"

Dir[File.join(__dir__, "tools", "*.rb")].each { |file| require_relative file }

module Crayons
  module Tools
    def self.new(tool_name)
      klass_name = tool_name.to_s.split("_").map(&:capitalize).join
      const_get(klass_name).new
    rescue NameError
      raise Crayons::ToolNotFoundError, "Tool :#{tool_name} not found"
    end
  end
end

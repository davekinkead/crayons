# frozen_string_literal: true
require_relative "tool"

require_relative "tools/bash"
require_relative "tools/read_file"
require_relative "tools/write_file"
require_relative "tools/edit_file"
require_relative "tools/haiku"
require_relative "tools/grep"
require_relative "tools/glob"
require_relative "tools/spawn_agent"
require_relative "tools/explore"

module Crayons
  class Tools
    @registry = {}

    class << self
      def register(name, tool_class)
        @registry[name.to_sym] = tool_class
      end

      def get(name)
        @registry[name.to_sym]
      end

      def load_builtin_tools
        register(:bash, Crayons::BashTool)
        register(:read_file, Crayons::ReadFileTool)
        register(:write_file, Crayons::WriteFileTool)
        register(:edit_file, Crayons::EditFileTool)
        register(:haiku, Crayons::HaikuTool)
        register(:grep, Crayons::GrepTool)
        register(:glob, Crayons::GlobTool)
        register(:spawn_agent, Crayons::SpawnAgentTool)
        register(:explore, Crayons::ExploreTool)
      end
    end

    load_builtin_tools
  end
end

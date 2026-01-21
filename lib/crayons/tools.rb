# frozen_string_literal: true
require_relative "tool"

require_relative "tools/bash"
require_relative "tools/read"
require_relative "tools/write"
require_relative "tools/edit"
require_relative "tools/haiku"
require_relative "tools/grep"
require_relative "tools/glob"
require_relative "tools/spawn_agent"
require_relative "tools/explore"
require_relative "tools/batch"

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
        register(:read, Crayons::ReadTool)
        register(:write, Crayons::WriteTool)
        register(:edit, Crayons::EditTool)
        register(:haiku, Crayons::HaikuTool)
        register(:grep, Crayons::GrepTool)
        register(:glob, Crayons::GlobTool)
        register(:spawn_agent, Crayons::SpawnAgentTool)
        register(:explore, Crayons::ExploreTool)
        register(:batch, Crayons::BatchTool)
      end
    end

    load_builtin_tools
  end
end

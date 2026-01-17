require 'ruby_llm'

require_relative "tools/bash_tool"
require_relative "tools/read_file_tool"
require_relative "tools/write_file_tool"
require_relative "tools/edit_file_tool"
require_relative "tools/haiku_tool"

module Ralph
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
        register(:bash, Ralph::BashTool)
        register(:read_file, Ralph::ReadFileTool)
        register(:write_file, Ralph::WriteFileTool)
        register(:edit_file, Ralph::EditFileTool)
        register(:haiku, Ralph::HaikuTool)
      end
    end

    load_builtin_tools
  end
end

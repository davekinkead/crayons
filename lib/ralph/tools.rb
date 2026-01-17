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
    end
  end
end

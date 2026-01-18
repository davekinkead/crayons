module Ralph
  class Tool
    class << self
      attr_reader :description, :parameters

      def description(text = nil)
        @description = text if text
        @description
      end

      def params(&block)
        @parameters = {}
        @params_dsl = DSL.new(@parameters)
        @params_dsl.instance_eval(&block)
      end
    end

    def execute(**kwargs)
      raise NotImplementedError
    end

    def schema
      {
        type: 'function',
        function: {
          name: self.class.name&.split('::')&.last || 'Unknown',
          description: self.class.description,
          parameters: {
            type: 'object',
            properties: self.class.parameters || {},
            required: []
          }
        }
      }
    end

    class DSL
      def initialize(parameters)
        @parameters = parameters
      end

      def string(name, description:)
        @parameters[name] = { type: 'string', description: }
      end
    end
  end
end

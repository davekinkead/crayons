module Ralph
  class Tool
    class << self
      def description(text)
        @description = text
      end

      def param(name, type: 'string', description: nil, required: true)
        @params ||= {}
        @params[name.to_sym] = {
          type: type,
          description: description,
          required: required
        }
      end

      def schema
        return nil unless @description

        {
          type: 'function',
          function: {
            name: to_s.split('::').last.downcase,
            description: @description,
            parameters: {
              type: 'object',
              properties: @params&.transform_values do |p|
                { type: p[:type], description: p[:description] }.compact
              end || {},
              required: @params&.select { |_, v| v[:required] }&.keys&.map(&:to_s) || []
            }
          }
        }
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@description, @description)
        subclass.instance_variable_set(:@params, @params&.dup)
      end
    end

    def call(**kwargs)
      raise NotImplementedError, 'Subclasses must implement #call'
    end
  end
end

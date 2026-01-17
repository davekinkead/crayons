module Ralph
  class Tool
    class << self
      def description(text)
        @description = text
      end

      def param(name, type: 'string', description: nil, required: false)
        @params ||= {}
        @params[name.to_sym] = {
          type: type,
          description: description,
          required: required
        }
      end

      def params
        @params || {}
      end

      def schema
        return nil unless @description

        {
          type: 'function',
          function: {
            name: to_s.split('::').last.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, ''),
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

    def name
      self.class.to_s.split('::').last
    end

    def description
      self.class.instance_variable_get(:@description)
    end

    def params
      self.class.params
    end
  end
end

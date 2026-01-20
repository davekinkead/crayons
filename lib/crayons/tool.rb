# frozen_string_literal: true
module Crayons
  class Tool
    class << self
      attr_reader :description, :parameters

      def description(text = nil)
        @description = text if text
        @description
      end

      def params(&)
        @parameters = {}
        @params_dsl = DSL.new(@parameters)
        @params_dsl.instance_eval(&)
      end
    end

    attr_reader :name, :description, :parameters

    def initialize
      @name = extract_name
      @description = self.class.description
      @parameters = self.class.parameters
    end

    private

    def extract_name
      return "unknown" unless self.class.name

      self.class.name
        .split("::")
        .last
        .gsub(/Tool$/, "")
        .downcase
    end

    def execute(**kwargs)
      raise NotImplementedError
    end

    class DSL
      def initialize(parameters)
        @parameters = parameters
      end

      def string(name, description:)
        @parameters[name] = { type: "string", description: }
      end
    end
  end
end

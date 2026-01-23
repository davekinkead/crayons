# frozen_string_literal: true

module Crayons
  class Tool
    def name
      raise NotImplementedError, "#{self.class} must implement #name"
    end

    def description
      raise NotImplementedError, "#{self.class} must implement #description"
    end

    def params
      raise NotImplementedError, "#{self.class} must implement #params"
    end

    def call(input = nil)
      raise NotImplementedError, "#{self.class} must implement #call"
    end
  end
end

# frozen_string_literal: true

module Crayons
  module Utils
    def self.symbolize_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key.to_sym] = value.is_a?(Hash) ? symbolize_keys(value) : value
      end
    end
  end
end

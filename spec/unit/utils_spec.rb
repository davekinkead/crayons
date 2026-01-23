# frozen_string_literal: true

require_relative "../../lib/utils"

RSpec.describe Crayons::Utils do
  describe ".symbolize_keys" do
    it "converts string keys to symbols in a simple hash" do
      hash = { "key1" => "value1", "key2" => "value2" }
      result = described_class.symbolize_keys(hash)

      expect(result).to eq({ key1: "value1", key2: "value2" })
    end

    it "handles nested hashes" do
      hash = { "outer" => { "inner" => "value" } }
      result = described_class.symbolize_keys(hash)

      expect(result).to eq({ outer: { inner: "value" } })
    end

    it "does not modify symbol keys" do
      hash = { existing_key: "value", "new_key" => "value" }
      result = described_class.symbolize_keys(hash)

      expect(result).to eq({ existing_key: "value", new_key: "value" })
    end

    it "preserves values that are not hashes" do
      hash = { "array" => [1, 2, 3], "string" => "test", "number" => 42 }
      result = described_class.symbolize_keys(hash)

      expect(result).to eq({
        array: [1, 2, 3],
        string: "test",
        number: 42
      })
    end

    it "handles deeply nested hashes" do
      hash = { "level1" => { "level2" => { "level3" => "deep value" } } }
      result = described_class.symbolize_keys(hash)

      expect(result).to eq({ level1: { level2: { level3: "deep value" } } })
    end

    it "returns a new hash without modifying the original" do
      original = { "key" => "value" }
      result = described_class.symbolize_keys(original)

      expect(original).to eq({ "key" => "value" })
      expect(result).to eq({ key: "value" })
      expect(original.keys.first).to be_a(String)
      expect(result.keys.first).to be_a(Symbol)
    end
  end
end

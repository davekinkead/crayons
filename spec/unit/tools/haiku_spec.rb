# frozen_string_literal: true

require_relative "../../../lib/tools/haiku"

RSpec.describe Crayons::Tools::Haiku do
  describe "#name" do
    it "returns 'haiku'" do
      expect(subject.name).to eq("haiku")
    end
  end

  describe "#description" do
    it "returns a description of the tool" do
      expect(subject.description).to be_a(String)
      expect(subject.description).not_to be_empty
    end
  end

  describe "#params" do
    it "returns empty array (no required parameters)" do
      expect(subject.params).to eq([])
    end
  end

  describe "#call" do
    it "generates a haiku" do
      result = subject.call

      expect(result).to be_a(Hash)
      expect(result[:success]).to be true
      expect(result[:result]).to be_a(String)
      expect(result[:result]).not_to be_empty
    end

    it "returns a haiku with 3 lines" do
      result = subject.call
      haiku = result[:result]
      lines = haiku.split("\n")

      expect(lines.length).to eq(3)
    end
  end
end

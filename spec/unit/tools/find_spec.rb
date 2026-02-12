# frozen_string_literal: true

require_relative "../../../lib/tools/find"

RSpec.describe Crayons::Tools::Find do
  describe "#name" do
    it "returns 'find'" do
      expect(subject.name).to eq("find")
    end
  end

  describe "#description" do
    it "returns a description of the tool" do
      expect(subject.description).to be_a(String)
      expect(subject.description).not_to be_empty
    end
  end

  describe "#params" do
    it "returns parameter definitions" do
      expect(subject.params).to be_an(Array)
      expect(subject.params.length).to eq(2)

      pattern_param = subject.params.first
      expect(pattern_param[:name]).to eq("pattern")
      expect(pattern_param[:required]).to be true

      path_param = subject.params.last
      expect(path_param[:name]).to eq("path")
      expect(path_param[:required]).to be false
    end
  end

  describe "#call" do
    it "requires pattern parameter" do
      expect { subject.call({}) }.to raise_error(KeyError, "pattern is required")
    end

    it "stores the directory used" do
      subject.call(pattern: "README*", path: ".")

      expect(subject.dir).to eq(".")
    end

    it "finds files matching pattern" do
      result = subject.call(pattern: "*.rb", path: "lib/tools")

      expect(result[:success]).to be true
      expect(result[:result][:matches]).to be_an(Array)
      expect(result[:result][:matches]).to include(a_string_ending_with("bash.rb"))
      expect(result[:result][:matches]).to include(a_string_ending_with("read_file.rb"))
    end

    it "returns error for non-existent path" do
      result = subject.call(pattern: "*", path: "/nonexistent/path/xyz123")

      expect(result[:success]).to be false
      expect(result[:result][:error]).to include("Directory not found")
    end

    it "handles no matches" do
      result = subject.call(pattern: "*.xyzxyz", path: "lib")

      expect(result[:success]).to be true
      expect(result[:result][:matches]).to eq([])
    end

    it "includes pattern and path in result" do
      result = subject.call(pattern: "*.rb", path: "lib/tools")

      expect(result[:result][:pattern]).to eq("*.rb")
      expect(result[:result][:path]).to eq("lib/tools")
    end
  end
end

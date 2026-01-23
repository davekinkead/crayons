# frozen_string_literal: true

require_relative "../../../lib/tools/grep"

RSpec.describe Crayons::Tools::Grep do
  describe "#name" do
    it "returns 'grep'" do
      expect(subject.name).to eq("grep")
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
      expect(subject.params.length).to eq(3)

      pattern_param = subject.params[0]
      expect(pattern_param[:name]).to eq("pattern")
      expect(pattern_param[:required]).to be true

      path_param = subject.params[1]
      expect(path_param[:name]).to eq("path")
      expect(path_param[:required]).to be false

      include_param = subject.params[2]
      expect(include_param[:name]).to eq("include")
      expect(include_param[:required]).to be false
    end
  end

  describe "#call" do
    it "requires pattern parameter" do
      expect { subject.call({}) }.to raise_error(KeyError, "pattern is required")
    end

    it "stores the directory used" do
      subject.call(pattern: "class", path: "/Users/davekinkead/Projects/crayons/lib/tools")

      expect(subject.dir).to eq("/Users/davekinkead/Projects/crayons/lib/tools")
    end

    it "defaults to the current directory" do
      result = subject.call(pattern: "RSpec")

      expect(subject.dir).to eq(Dir.pwd)
      expect(result[:success]).to be true
    end

    it "searches file contents by pattern" do
      result = subject.call(pattern: "class Tool", path: "/Users/davekinkead/Projects/crayons/lib")

      expect(result[:success]).to be true
      expect(result[:result][:matches]).to be_an(Array)
      expect(result[:result][:matches].first).to include("class Tool")
    end

    it "returns sorted matches" do
      result = subject.call(pattern: "class", path: "/Users/davekinkead/Projects/crayons/lib/tools")

      expect(result[:success]).to be true
      expect(result[:result][:matches]).to eq(result[:result][:matches].sort)
    end

    it "returns error for non-existent path" do
      result = subject.call(pattern: "test", path: "/nonexistent/path/xyz123")

      expect(result[:success]).to be false
      expect(result[:result][:error]).to include("Directory not found")
    end

    it "handles no matches" do
      result = subject.call(pattern: "NONEXISTENT_PATTERN_XYZ", path: "/Users/davekinkead/Projects/crayons/lib")

      expect(result[:success]).to be true
      expect(result[:result][:matches]).to eq([])
    end

    it "includes pattern and path in result" do
      result = subject.call(pattern: "class", path: "/Users/davekinkead/Projects/crayons/lib/tools")

      expect(result[:result][:pattern]).to eq("class")
      expect(result[:result][:path]).to eq("/Users/davekinkead/Projects/crayons/lib/tools")
    end

    it "filters files by include pattern" do
      result = subject.call(pattern: "class", path: "/Users/davekinkead/Projects/crayons/lib", include: "*.rb")

      expect(result[:success]).to be true
      result[:result][:matches].each do |match|
        expect(match.split(":").first).to end_with(".rb")
      end
    end
  end
end

# frozen_string_literal: true

require "tempfile"
require_relative "../../../lib/tools/read_file"

RSpec.describe Crayons::Tools::ReadFile do
  describe "#name" do
    it "returns 'read_file'" do
      expect(subject.name).to eq("read_file")
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
      expect(subject.params.length).to eq(1)

      filepath_param = subject.params.first
      expect(filepath_param[:name]).to eq("filepath")
      expect(filepath_param[:required]).to be true
    end
  end

  describe "#call" do
    let(:temp_file) { Tempfile.new("test_read") }
    let(:temp_path) { temp_file.path }

    before do
      temp_file.write("test content")
      temp_file.close
    end

    after do
      temp_file.unlink
    end

    it "reads file contents successfully" do
      result = subject.call(filepath: temp_path)

      expect(result[:success]).to be true
      expect(result[:result]).to have_key(:content)
      expect(result[:result][:content]).to eq("test content")
      expect(result[:result][:filepath]).to eq(temp_path)
    end

    it "requires filepath parameter" do
      expect { subject.call({}) }.to raise_error(KeyError, "filepath is required")
    end

    it "returns error for non-existent file" do
      result = subject.call(filepath: "/nonexistent/file.txt")

      expect(result[:success]).to be false
      expect(result[:result][:error]).to include("File not found")
    end

    it "returns error for directory path" do
      result = subject.call(filepath: Dir.tmpdir)

      expect(result[:success]).to be false
      expect(result[:result][:error]).to include("not a file")
    end
  end
end

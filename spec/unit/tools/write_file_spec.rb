# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../../../lib/tools/write_file"

RSpec.describe Crayons::Tools::WriteFile do
  describe "#name" do
    it "returns 'write_file'" do
      expect(subject.name).to eq("write_file")
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

      filepath_param = subject.params.find { |p| p[:name] == "filepath" }
      expect(filepath_param).not_to be_nil
      expect(filepath_param[:required]).to be true

      content_param = subject.params.find { |p| p[:name] == "content" }
      expect(content_param).not_to be_nil
      expect(content_param[:required]).to be true
    end
  end

  describe "#call" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:temp_path) { File.join(temp_dir, "test_write.txt") }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it "writes content to a new file successfully" do
      result = subject.call(filepath: temp_path, content: "new content")

      expect(result[:success]).to be true
      expect(result[:result][:filepath]).to eq(temp_path)
      expect(result[:result][:bytes_written]).to eq("new content".bytesize)
      expect(File.read(temp_path)).to eq("new content")
    end

    it "overwrites existing file content" do
      File.write(temp_path, "original content")
      result = subject.call(filepath: temp_path, content: "updated content")

      expect(result[:success]).to be true
      expect(File.read(temp_path)).to eq("updated content")
    end

    it "requires filepath parameter" do
      expect { subject.call({ content: "test" }) }.to raise_error(KeyError, "filepath is required")
    end

    it "requires content parameter" do
      expect { subject.call({ filepath: temp_path }) }.to raise_error(KeyError, "content is required")
    end

    it "returns error when directory does not exist" do
      result = subject.call(filepath: "/nonexistent/dir/file.txt", content: "test")

      expect(result[:success]).to be false
      expect(result[:result][:error]).to include("Directory not found")
    end
  end
end

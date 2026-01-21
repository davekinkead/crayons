# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons"

RSpec.describe Crayons::ReadTool do
  let(:tool) { Crayons::ReadTool.new }
  let(:nonexistent_file) { "/nonexistent/file.txt" }
  let(:temp_dir) { "/tmp/crayons_test_#{Time.now.to_i}" }
  let(:test_file_content) { "This is test content" }
  let(:test_file) { File.join(temp_dir, "test.txt") }

  before do
    FileUtils.mkdir_p(temp_dir)
    File.write(test_file, test_file_content)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "single file reading (backwards compatibility)" do
    it "returns the file contents" do
      result = tool.execute(file_path: test_file)
      expect(result[:content]).to eq(test_file_content)
    end

    it "includes success status when file is read successfully" do
      result = tool.execute(file_path: test_file)
      expect(result[:success]).to be true
    end

    it "includes the file path in the response" do
      result = tool.execute(file_path: test_file)
      expect(result[:file_path]).to eq(test_file)
    end

    it "returns error message when file does not exist" do
      result = tool.execute(file_path: nonexistent_file)
      expect(result[:error]).to match(/File not found/)
    end

    it "includes failure status when file does not exist" do
      result = tool.execute(file_path: nonexistent_file)
      expect(result[:success]).to be false
    end

    it "returns error message when permission is denied" do
      unreadable_file = File.join(temp_dir, "unreadable.txt")
      File.write(unreadable_file, "content")
      File.chmod(0o000, unreadable_file)

      result = tool.execute(file_path: unreadable_file)
      expect(result[:error]).to match(/Permission denied|Error/i)
      expect(result[:success]).to be false
    ensure
      File.chmod(0o644, unreadable_file) if File.exist?(unreadable_file)
    end

    it "returns error message when path is a directory" do
      result = tool.execute(file_path: temp_dir)
      expect(result[:error]).to match(/Is a directory|Error/i)
      expect(result[:success]).to be false
    end
  end

  describe "multiple file reading" do
    let(:file1) { File.join(temp_dir, "file1.txt") }
    let(:file2) { File.join(temp_dir, "file2.txt") }
    let(:file3) { File.join(temp_dir, "file3.txt") }

    before do
      File.write(file1, "content of file 1")
      File.write(file2, "content of file 2")
      File.write(file3, "content of file 3")
    end

    it "returns hash with file paths as keys" do
      result = tool.execute(file_path: [file1, file2, file3])
      expect(result.keys).to contain_exactly(file1, file2, file3)
    end

    it "returns content for each file" do
      result = tool.execute(file_path: [file1, file2])
      expect(result[file1][:content]).to eq("content of file 1")
      expect(result[file2][:content]).to eq("content of file 2")
    end

    it "returns success status for each successfully read file" do
      result = tool.execute(file_path: [file1, file2, file3])
      expect(result[file1][:success]).to be true
      expect(result[file2][:success]).to be true
      expect(result[file3][:success]).to be true
    end

    it "includes file path for each result" do
      result = tool.execute(file_path: [file1, file2])
      expect(result[file1][:file_path]).to eq(file1)
      expect(result[file2][:file_path]).to eq(file2)
    end
  end

  describe "mixed success and error scenarios with multiple files" do
    let(:file1) { File.join(temp_dir, "file1.txt") }
    let(:file2) { File.join(temp_dir, "file2.txt") }
    let(:sub_dir) { File.join(temp_dir, "subdir") }

    before do
      File.write(file1, "content of file 1")
      FileUtils.mkdir_p(sub_dir)
    end

    it "handles mix of existing and non-existing files" do
      result = tool.execute(file_path: [file1, nonexistent_file, file2])
      expect(result.keys).to contain_exactly(file1, nonexistent_file, file2)
    end

    it "returns content for existing files" do
      result = tool.execute(file_path: [file1, nonexistent_file])
      expect(result[file1][:content]).to eq("content of file 1")
    end

    it "returns success for existing files" do
      result = tool.execute(file_path: [file1, nonexistent_file])
      expect(result[file1][:success]).to be true
    end

    it "returns error for non-existing files" do
      result = tool.execute(file_path: [file1, nonexistent_file])
      expect(result[nonexistent_file][:error]).to match(/File not found/)
    end

    it "returns failure for non-existing files" do
      result = tool.execute(file_path: [file1, nonexistent_file])
      expect(result[nonexistent_file][:success]).to be false
    end

    it "returns error when file path is a directory" do
      result = tool.execute(file_path: [file1, sub_dir])
      expect(result[sub_dir][:error]).to match(/Is a directory|Error/i)
      expect(result[sub_dir][:success]).to be false
    end

    context "with permission denied errors" do
      let(:unreadable_file) { File.join(temp_dir, "unreadable.txt") }

      before do
        File.write(unreadable_file, "content")
        File.chmod(0o000, unreadable_file)
      end

      after do
        File.chmod(0o644, unreadable_file) if File.exist?(unreadable_file)
      end

      it "returns error for unreadable file among readable files" do
        result = tool.execute(file_path: [file1, unreadable_file])
        expect(result[unreadable_file][:error]).to match(/Permission denied|Error/i)
        expect(result[unreadable_file][:success]).to be false
      end

      it "continues reading other files after permission error" do
        result = tool.execute(file_path: [file1, unreadable_file, file2])
        expect(result[file1][:success]).to be true
        expect(result[file1][:content]).to eq("content of file 1")
      end
    end
  end

  describe "edge cases" do
    context "when no files are requested" do
      it "returns empty hash when no files provided" do
        result = tool.execute(file_path: [])
        expect(result).to eq({})
      end
    end

    context "when single file is provided as array" do
      it "reads file contents correctly" do
        result = tool.execute(file_path: [test_file])
        expect(result[test_file][:content]).to eq(test_file_content)
        expect(result[test_file][:success]).to be true
      end
    end

    context "when duplicate file paths are provided" do
      it "handles duplicate paths by returning single result (hash keys are unique)" do
        result = tool.execute(file_path: [test_file, test_file])
        expect(result.keys).to eq([test_file])
        expect(result[test_file][:content]).to eq(test_file_content)
        expect(result[test_file][:success]).to be true
      end
    end

    context "when file paths contain special characters" do
      let(:special_char_file) { File.join(temp_dir, "file with spaces.txt") }
      let(:unicode_file) { File.join(temp_dir, "файл.txt") }

      before do
        File.write(special_char_file, "content with spaces")
        File.write(unicode_file, "unicode content")
      end

      it "reads files with spaces in name" do
        result = tool.execute(file_path: [special_char_file])
        expect(result[special_char_file][:content]).to eq("content with spaces")
        expect(result[special_char_file][:success]).to be true
      end

      it "reads files with unicode characters in name" do
        result = tool.execute(file_path: [unicode_file])
        expect(result[unicode_file][:content]).to eq("unicode content")
        expect(result[unicode_file][:success]).to be true
      end

      it "handles multiple files with various special characters" do
        result = tool.execute(file_path: [special_char_file, unicode_file])
        expect(result.keys).to contain_exactly(special_char_file, unicode_file)
        expect(result[special_char_file][:success]).to be true
        expect(result[unicode_file][:success]).to be true
      end
    end

    context "when handling large files" do
      let(:large_file) { File.join(temp_dir, "large.txt") }
      let(:large_content) { "x" * 10_000 }

      before do
        File.write(large_file, large_content)
      end

      it "reads large file content successfully" do
        result = tool.execute(file_path: [large_file])
        expect(result[large_file][:content]).to eq(large_content)
        expect(result[large_file][:success]).to be true
      end

      it "handles large files mixed with other files" do
        result = tool.execute(file_path: [test_file, large_file])
        expect(result[test_file][:content]).to eq(test_file_content)
        expect(result[large_file][:content]).to eq(large_content)
        expect(result[test_file][:success]).to be true
        expect(result[large_file][:success]).to be true
      end
    end

    context "when handling empty files" do
      let(:empty_file) { File.join(temp_dir, "empty.txt") }

      before do
        File.write(empty_file, "")
      end

      it "returns empty content for empty file" do
        result = tool.execute(file_path: [empty_file])
        expect(result[empty_file][:content]).to eq("")
        expect(result[empty_file][:success]).to be true
      end

      it "handles empty files in multiple file request" do
        result = tool.execute(file_path: [test_file, empty_file])
        expect(result[empty_file][:content]).to eq("")
        expect(result[test_file][:content]).to eq(test_file_content)
      end
    end

    context "when reading files with newlines and special content" do
      let(:multiline_file) { File.join(temp_dir, "multiline.txt") }
      let(:multiline_content) { "line1\nline2\nline3" }

      before do
        File.write(multiline_file, multiline_content)
      end

      it "preserves newlines in file content" do
        result = tool.execute(file_path: [multiline_file])
        expect(result[multiline_file][:content]).to eq(multiline_content)
        expect(result[multiline_file][:success]).to be true
      end
    end
  end
end

# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons"

RSpec.describe Crayons::BatchTool do
  let(:tool) { Crayons::BatchTool.new }
  let(:temp_dir) { "/tmp/crayons_batch_test_#{Time.now.to_i}" }
  let(:test_file) { File.join(temp_dir, "test.txt") }
  let(:test_content) { "test content" }

  before do
    FileUtils.mkdir_p(temp_dir)
    File.write(test_file, test_content)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "basic execution" do
    it "executes a single tool call in batch" do
      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } }
      ])

      expect(result).to be_a(Hash)
      expect(result[:success]).to be true
      expect(result[:results]).to be_an(Array)
      expect(result[:results].length).to eq(1)
      expect(result[:results][0][:tool_name]).to eq("read")
      expect(result[:results][0][:arguments]).to eq({ file_path: test_file })
      expect(result[:results][0][:result][:content]).to eq(test_content)
      expect(result[:results][0][:success]).to be true
      expect(result[:results][0][:error]).to be_nil
    end

    it "executes multiple different tools in batch" do
      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } },
        { tool_name: "bash", arguments: { command: "echo hello" } }
      ])

      expect(result[:success]).to be true
      expect(result[:results].length).to eq(2)

      expect(result[:results][0][:tool_name]).to eq("read")
      expect(result[:results][0][:result][:content]).to eq(test_content)
      expect(result[:results][0][:success]).to be true

      expect(result[:results][1][:tool_name]).to eq("bash")
      expect(result[:results][1][:result][:output]).to include("hello")
      expect(result[:results][1][:success]).to be true
    end

    it "returns results in the same order as calls" do
      file2 = File.join(temp_dir, "file2.txt")
      file3 = File.join(temp_dir, "file3.txt")
      File.write(file2, "content 2")
      File.write(file3, "content 3")

      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } },
        { tool_name: "read", arguments: { file_path: file2 } },
        { tool_name: "read", arguments: { file_path: file3 } }
      ])

      expect(result[:results][0][:result][:content]).to eq(test_content)
      expect(result[:results][1][:result][:content]).to eq("content 2")
      expect(result[:results][2][:result][:content]).to eq("content 3")
    end

    it "returns overall success when all tools succeed" do
      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } },
        { tool_name: "bash", arguments: { command: "echo test" } }
      ])

      expect(result[:success]).to be true
      expect(result[:errors]).to be_empty
    end
  end

  describe "error handling" do
    it "continues execution when one tool fails" do
      nonexistent_file = "/nonexistent/file.txt"

      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } },
        { tool_name: "read", arguments: { file_path: nonexistent_file } },
        { tool_name: "bash", arguments: { command: "echo hello" } }
      ])

      expect(result[:success]).to be false
      expect(result[:results].length).to eq(3)

      expect(result[:results][0][:success]).to be true
      expect(result[:results][0][:result][:content]).to eq(test_content)

      expect(result[:results][1][:success]).to be false
      expect(result[:results][1][:error]).to match(/File not found/)

      expect(result[:results][2][:success]).to be true
      expect(result[:results][2][:result][:output]).to include("hello")
    end

    it "includes error details for failed tools" do
      nonexistent_file = "/nonexistent/file.txt"

      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: nonexistent_file } }
      ])

      expect(result[:success]).to be false
      expect(result[:errors].length).to eq(1)
      expect(result[:errors][0][:tool_name]).to eq("read")
      expect(result[:errors][0][:arguments]).to eq({ file_path: nonexistent_file })
      expect(result[:errors][0][:error]).to match(/File not found/)
    end

    it "returns empty errors array when all tools succeed" do
      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } }
      ])

      expect(result[:success]).to be true
      expect(result[:errors]).to eq([])
    end
  end

  describe "deduplication" do
    it "deduplicates identical tool calls" do
      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } },
        { tool_name: "read", arguments: { file_path: test_file } }
      ])

      expect(result[:results].length).to eq(2)
      expect(result[:results][0][:result][:content]).to eq(test_content)
      expect(result[:results][1][:result][:content]).to eq(test_content)
    end

    it "does not deduplicate calls with same tool but different arguments" do
      file2 = File.join(temp_dir, "file2.txt")
      File.write(file2, "different content")

      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } },
        { tool_name: "read", arguments: { file_path: file2 } }
      ])

      expect(result[:results].length).to eq(2)
      expect(result[:results][0][:result][:content]).to eq(test_content)
      expect(result[:results][1][:result][:content]).to eq("different content")
    end
  end

  describe "edge cases" do
    it "handles empty calls array" do
      result = tool.execute(calls: [])

      expect(result[:success]).to be true
      expect(result[:results]).to eq([])
      expect(result[:errors]).to eq([])
    end

    it "returns error for unknown tool name" do
      result = tool.execute(calls: [
        { tool_name: "nonexistent_tool", arguments: { foo: "bar" } }
      ])

      expect(result[:success]).to be false
      expect(result[:results][0][:success]).to be false
      expect(result[:results][0][:error]).to match(/Tool not found/)
    end

    it "handles malformed arguments" do
      result = tool.execute(calls: [
        { tool_name: "read", arguments: {} }
      ])

      expect(result[:results][0][:success]).to be false
      expect(result[:results][0][:error]).not_to be_nil
    end

    it "handles mixed valid and invalid tool calls" do
      result = tool.execute(calls: [
        { tool_name: "read", arguments: { file_path: test_file } },
        { tool_name: "unknown_tool", arguments: {} },
        { tool_name: "bash", arguments: { command: "echo test" } }
      ])

      expect(result[:results].length).to eq(3)
      expect(result[:results][0][:success]).to be true
      expect(result[:results][1][:success]).to be false
      expect(result[:results][2][:success]).to be true
    end
  end

  describe "concurrent execution" do
    it "executes tools concurrently for performance" do
      slow_files = (1..3).map do |i|
        file = File.join(temp_dir, "slow_#{i}.txt")
        File.write(file, "content #{i}")
        file
      end

      start_time = Time.now

      result = tool.execute(calls: slow_files.map do |file|
        { tool_name: "read", arguments: { file_path: file } }
      end)

      end_time = Time.now

      expect(result[:success]).to be true
      expect(result[:results].length).to eq(3)

      # With concurrent execution, this should be faster than sequential
      # (though hard to test precisely, we just verify it completes)
      expect(end_time - start_time).to be < 5
    end
  end

  describe "with multiple file reading" do
    let(:files) do
      (1..5).map do |i|
        file = File.join(temp_dir, "file_#{i}.txt")
        File.write(file, "content #{i}")
        file
      end
    end

    it "efficiently reads multiple files via batch" do
      result = tool.execute(calls: files.map do |file|
        { tool_name: "read", arguments: { file_path: file } }
      end)

      expect(result[:success]).to be true
      expect(result[:results].length).to eq(5)

      files.each_with_index do |_file, idx|
        expect(result[:results][idx][:tool_name]).to eq("read")
        expect(result[:results][idx][:success]).to be true
        expect(result[:results][idx][:result][:content]).to eq("content #{idx + 1}")
      end
    end
  end
end

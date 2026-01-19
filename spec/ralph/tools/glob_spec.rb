# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/ralph"

RSpec.describe Ralph::GlobTool do
  let(:tool) { Ralph::GlobTool.new }
  let(:test_dir) { File.expand_path("../../fixtures", __dir__) }

  before do
    FileUtils.mkdir_p(File.join(test_dir, "subdir"))
    FileUtils.mkdir_p(File.join(test_dir, "nested"))
    File.write(File.join(test_dir, "test1.rb"), "content")
    File.write(File.join(test_dir, "test2.rb"), "content")
    File.write(File.join(test_dir, "test3.txt"), "content")
    File.write(File.join(test_dir, "subdir", "nested.rb"), "content")
    File.write(File.join(test_dir, "nested", "deep.rb"), "content")
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  it "finds files matching glob pattern" do
    result = tool.execute(command: "find #{test_dir} -maxdepth 1 -name '*.rb' -type f")
    expect(result[:files].length).to eq(2)
    expect(result[:files].all? { |f| f.end_with?(".rb") }).to be true
  end

  it "supports recursive patterns" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f")
    expect(result[:files].length).to be >= 3
    expect(result[:files].any? { |f| f.include?("subdir") }).to be true
  end

  it "searches in specific directory" do
    subdir = File.join(test_dir, "subdir")
    result = tool.execute(command: "find #{subdir} -maxdepth 1 -name '*.rb' -type f")
    expect(result[:files].length).to eq(1)
    expect(result[:files].first).to include("subdir")
  end

  it "limits results" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f | head -n 2")
    expect(result[:files].length).to be <= 2
  end

  it "returns absolute file paths" do
    result = tool.execute(command: "find #{test_dir} -maxdepth 1 -name '*.rb' -type f")
    expect(result[:files].first).to start_with("/")
  end

  it "handles no matches" do
    result = tool.execute(command: "find #{test_dir} -name '*.nonexistent' -type f")
    expect(result[:files]).to eq([])
  end

  it "handles non-existent directory" do
    result = tool.execute(command: "find /nonexistent/path -name '*' -type f")
    expect(result[:exit_status]).not_to eq(0)
  end

  it "rejects commands that do not start with find" do
    result = tool.execute(command: "ls #{test_dir}")
    expect(result[:error]).to eq("Command must start with 'find'")
    expect(result[:files]).to eq([])
  end

  it "allows safe pipe commands like head" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f | head -n 1")
    expect(result[:files].length).to be <= 1
  end

  it "rejects commands with semicolon" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f; rm -rf /")
    expect(result[:error]).to include("unsafe operators")
    expect(result[:files]).to eq([])
  end

  it "rejects commands with ampersand" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f & rm -rf /")
    expect(result[:error]).to include("unsafe operators")
    expect(result[:files]).to eq([])
  end

  it "rejects commands with backticks" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f `rm -rf /`")
    expect(result[:error]).to include("unsafe operators")
    expect(result[:files]).to eq([])
  end

  it "rejects commands with dollar sign substitution" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f $(rm -rf /)")
    expect(result[:error]).to include("unsafe operators")
    expect(result[:files]).to eq([])
  end

  it "rejects commands with output redirection" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f > /tmp/output")
    expect(result[:error]).to include("output redirection")
    expect(result[:files]).to eq([])
  end

  it "rejects pipes to dangerous commands" do
    result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f | rm /tmp/file")
    expect(result[:error]).to include("Piped command 'rm' is not allowed")
    expect(result[:files]).to eq([])
  end

  it "allows pipes to various safe commands" do
    safe_commands = ["head -n 1", "tail -n 1", "sort", "uniq", "wc -l"]
    safe_commands.each do |safe_cmd|
      result = tool.execute(command: "find #{test_dir} -name '*.rb' -type f | #{safe_cmd}")
      expect(result[:error]).to be_nil, "Failed for command: | #{safe_cmd}"
    end
  end

  after do
    FileUtils.rm_rf(test_dir)
  end
end

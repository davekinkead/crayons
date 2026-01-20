# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons"

RSpec.describe Crayons::GrepTool do
  let(:tool) { Crayons::GrepTool.new }
  let(:test_dir) { File.expand_path("../../fixtures", __dir__) }

  before do
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, "test1.rb"), "class Test1\n  def hello\n    'hello world'\n  end\nend")
    File.write(File.join(test_dir, "test2.rb"), "class Test2\n  def goodbye\n    'goodbye world'\n  end\nend")
    File.write(File.join(test_dir, "test3.txt"), "hello world")
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  it "searches for pattern in files" do
    result = tool.execute(command: "rg -n hello #{test_dir}")
    expect(result[:matches]).to be_an(Array)
    expect(result[:matches].length).to be > 0
    expect(result[:matches].first[:content]).to include("hello")
  end

  it "searches in specific directory" do
    result = tool.execute(command: "rg -n hello #{test_dir}")
    expect(result[:matches].length).to be > 0
  end

  it "filters files by glob pattern" do
    result = tool.execute(command: "rg -n -g '*.rb' hello #{test_dir}")
    expect(result[:matches].length).to be > 0
    expect(result[:matches].all? { |m| m[:file].end_with?(".rb") }).to be true
  end

  it "supports case insensitive search" do
    result = tool.execute(command: "rg -n -i HELLO #{test_dir}")
    expect(result[:matches].length).to be > 0
  end

  it "limits results" do
    result = tool.execute(command: "rg -n world #{test_dir} | head -n 2")
    expect(result[:matches].length).to be <= 2
  end

  it "includes line numbers" do
    result = tool.execute(command: "rg -n hello #{test_dir}")
    expect(result[:matches].first[:line_number]).to be_an(Integer)
  end

  it "returns structured output with file, line number, and content" do
    result = tool.execute(command: "rg -n hello #{test_dir}")
    match = result[:matches].first
    expect(match[:file]).to be_a(String)
    expect(match[:line_number]).to be_an(Integer)
    expect(match[:content]).to be_a(String)
  end

  it "handles no matches" do
    result = tool.execute(command: "rg -n nonexistent_pattern_xyz #{test_dir}")
    expect(result[:matches]).to eq([])
  end

  it "handles non-existent directory" do
    result = tool.execute(command: "rg hello /nonexistent/path")
    expect(result[:exit_status]).not_to eq(0)
  end

  it "rejects commands that do not start with rg" do
    result = tool.execute(command: "grep hello #{test_dir}")
    expect(result[:error]).to eq("Command must start with 'rg'")
    expect(result[:matches]).to eq([])
  end

  it "allows safe pipe commands like head" do
    result = tool.execute(command: "rg -n hello #{test_dir} | head -n 1")
    expect(result[:matches].length).to be <= 1
  end

  it "rejects commands with semicolon" do
    result = tool.execute(command: "rg -n hello #{test_dir}; rm -rf /")
    expect(result[:error]).to include("unsafe operators")
    expect(result[:matches]).to eq([])
  end

  it "rejects commands with ampersand" do
    result = tool.execute(command: "rg -n hello #{test_dir} & rm -rf /")
    expect(result[:error]).to include("unsafe operators")
    expect(result[:matches]).to eq([])
  end

  it "rejects commands with backticks" do
    result = tool.execute(command: "rg -n hello #{test_dir} `rm -rf /`")
    expect(result[:error]).to include("unsafe operators")
    expect(result[:matches]).to eq([])
  end

  it "rejects commands with dollar sign substitution" do
    result = tool.execute(command: "rg -n hello #{test_dir} $(rm -rf /)")
    expect(result[:error]).to include("unsafe operators")
    expect(result[:matches]).to eq([])
  end

  it "rejects commands with output redirection" do
    result = tool.execute(command: "rg -n hello #{test_dir} > /tmp/output")
    expect(result[:error]).to include("unsafe output redirection")
    expect(result[:matches]).to eq([])
  end

  it "rejects pipes to dangerous commands" do
    result = tool.execute(command: "rg -n hello #{test_dir} | rm /tmp/file")
    expect(result[:error]).to include("Piped command 'rm' is not allowed")
    expect(result[:matches]).to eq([])
  end

  it "allows pipes to various safe commands" do
    safe_commands = ["head -n 1", "tail -n 1", "sort", "uniq", "wc -l", "grep hello"]
    safe_commands.each do |safe_cmd|
      result = tool.execute(command: "rg -n hello #{test_dir} | #{safe_cmd}")
      expect(result[:error]).to be_nil, "Failed for command: | #{safe_cmd}"
    end
  end
end

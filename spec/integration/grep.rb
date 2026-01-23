# frozen_string_literal: true

require_relative "../../lib/tools"
require "fileutils"
require "tmpdir"

RSpec.describe "Grep tool integration tests" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:test_files) do
    {
      "test1.rb" => "def hello\n  puts 'world'\nend",
      "test2.rb" => "def goodbye\n  puts 'later'\nend",
      "test.py" => "def hello:\n  print('world')",
      "nested/file.rb" => "class Hello\n  def world\n  end\nend",
      "nested/other.txt" => "hello world"
    }
  end

  before do
    test_files.each do |path, content|
      full_path = File.join(temp_dir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
    end
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  it "searches file contents by pattern" do
    tool = Crayons::Tools.new(:grep)
    result = tool.call(pattern: "def hello", path: temp_dir)

    expect(result[:success]).to be true
    expect(result[:result][:matches]).to be_an(Array)
    expect(result[:result][:matches].length).to eq(2)
  end

  it "returns file paths and line numbers" do
    tool = Crayons::Tools.new(:grep)
    result = tool.call(pattern: "def hello", path: temp_dir)

    expect(result[:success]).to be true
    first_match = result[:result][:matches].find { |m| m.include?("test1.rb") }
    expect(first_match).to include(":1:")
  end

  it "filters files by include pattern" do
    tool = Crayons::Tools.new(:grep)
    result = tool.call(pattern: "def", path: temp_dir, include: "*.rb")

    expect(result[:success]).to be true
    expect(result[:result][:matches].length).to eq(3)
    expect(result[:result][:matches].map { |m| m.split(":").first }.all? { |m| m.end_with?(".rb") }).to be true
  end

  it "handles no matches" do
    tool = Crayons::Tools.new(:grep)
    result = tool.call(pattern: "NONEXISTENT_PATTERN_XYZ", path: temp_dir)

    expect(result[:success]).to be true
    expect(result[:result][:matches]).to eq([])
  end

  it "handles regex patterns" do
    tool = Crayons::Tools.new(:grep)
    result = tool.call(pattern: "def .*", path: temp_dir)

    expect(result[:success]).to be true
    expect(result[:result][:matches].length).to be >= 3
  end
end

# frozen_string_literal: true

require_relative "../../lib/tools"
require "fileutils"
require "tmpdir"

RSpec.describe "Find tool integration tests" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:test_files) do
    {
      "test1.rb" => "content1",
      "test2.rb" => "content2",
      "test.py" => "python content",
      "nested/file.rb" => "nested content",
      "nested/other.txt" => "text content"
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

  it "finds files matching a pattern" do
    tool = Crayons::Tools.new(:find)
    result = tool.call(pattern: "*.rb", path: temp_dir)

    expect(result[:success]).to be true
    expect(result[:result][:matches]).to be_an(Array)
    expect(result[:result][:matches].length).to eq(3)
    expect(result[:result][:matches]).to include(a_string_ending_with("test1.rb"))
    expect(result[:result][:matches]).to include(a_string_ending_with("test2.rb"))
    expect(result[:result][:matches]).to include(a_string_ending_with("nested/file.rb"))
  end

  it "finds files recursively" do
    tool = Crayons::Tools.new(:find)
    result = tool.call(pattern: "*.rb", path: temp_dir)

    expect(result[:success]).to be true
    expect(result[:result][:matches].length).to eq(3)
  end

  it "handles no matches" do
    tool = Crayons::Tools.new(:find)
    result = tool.call(pattern: "*.xyz", path: temp_dir)

    expect(result[:success]).to be true
    expect(result[:result][:matches]).to eq([])
  end
end

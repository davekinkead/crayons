# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons"

RSpec.describe Crayons::EditFileTool do
  let(:tool) { Crayons::EditFileTool.new }
  let(:temp_file) { "/tmp/test_edit_#{Time.now.to_i}.txt" }

  before do
    File.write(temp_file, "Hello World\nGoodbye\n")
  end

  after do
    File.delete(temp_file)
  end

  it "replaces single occurrence" do
    result = tool.execute(file_path: temp_file, old_string: "World", new_string: "Universe")
    expect(result[:success]).to be true
    expect(File.read(temp_file)).to eq("Hello Universe\nGoodbye\n")
  end

  it "returns error for non-existent file" do
    result = tool.execute(file_path: "/nonexistent/file.txt", old_string: "test", new_string: "new")
    expect(result[:error]).to match(/File not found/)
  end

  it "returns error for string not found" do
    result = tool.execute(file_path: temp_file, old_string: "NotFound", new_string: "new")
    expect(result[:error]).to eq("String not found in file")
  end

  it "returns error for multiple occurrences" do
    File.write(temp_file, "Hello World\nGoodbye World\n")
    result = tool.execute(file_path: temp_file, old_string: "World", new_string: "Universe")
    expect(result[:error]).to eq("String found multiple times - use replace_all parameter")
  end
end

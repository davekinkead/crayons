# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons"

RSpec.describe Crayons::WriteFileTool do
  let(:tool) { Crayons::WriteFileTool.new }
  let(:temp_file) { "/tmp/test_#{Time.now.to_i}.txt" }

  after do
    File.delete(temp_file)
  end

  it "writes content to file" do
    result = tool.execute(file_path: temp_file, content: "test content")
    expect(result[:success]).to be true
    expect(result[:bytes_written]).to eq(12)
    expect(File.read(temp_file)).to eq("test content")
  end
end

# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons"

RSpec.describe Crayons::ReadFileTool do
  let(:tool) { Crayons::ReadFileTool.new }

  it "reads file contents" do
    result = tool.execute(file_path: File.expand_path("../../../Gemfile", __dir__))
    expect(result[:content]).to include("rspec")
  end

  it "returns error for non-existent file" do
    result = tool.execute(file_path: "/nonexistent/file.txt")
    expect(result[:error]).to match(/File not found/)
  end
end

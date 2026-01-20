# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons"

RSpec.describe Crayons::BashTool do
  let(:tool) { Crayons::BashTool.new }

  it "executes bash command and returns output" do
    result = tool.execute(command: 'echo "hello world"')
    expect(result[:output]).to include("hello world")
    expect(result[:exit_status]).to eq(0)
  end

  it "handles command errors gracefully" do
    result = tool.execute(command: "exit 1")
    expect(result[:exit_status]).to eq(1)
  end
end

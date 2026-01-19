# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/ralph"

RSpec.describe Ralph::HaikuTool do
  let(:tool) { Ralph::HaikuTool.new }

  it "generates haiku on topic" do
    result = tool.execute(topic: "programming")
    expect(result).to be_a(String)
    expect(result.lines.count).to be <= 3
  end
end

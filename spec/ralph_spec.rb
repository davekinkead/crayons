# frozen_string_literal: true
require "spec_helper"
require_relative "../lib/ralph"

RSpec.describe Ralph do
  it "has a version number" do
    expect(Ralph::VERSION).not_to be_nil
  end
end

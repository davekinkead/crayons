# frozen_string_literal: true
require "spec_helper"
require_relative "../../lib/crayons"

RSpec.describe Crayons do
  it "has a version number" do
    expect(Crayons::VERSION).not_to be_nil
  end
end

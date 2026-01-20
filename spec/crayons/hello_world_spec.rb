# frozen_string_literal: true
require "spec_helper"
require_relative "../../lib/crayons"

RSpec.describe Crayons::HelloWorld do
  describe ".hello" do
    it "returns the greeting message" do
      expect(described_class.hello).to eq("Hello, World. I am alive!")
    end
  end
end

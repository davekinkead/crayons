# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Server::PortFinder do
  describe "#find_available_port" do
    it "returns 4567 when port 4567 is available" do
      allow(described_class).to receive(:port_available?).with(4567).and_return(true)

      result = described_class.find_available_port

      expect(result).to eq(4567)
    end

    it "returns 4568 when 4567 is unavailable but 4568 is available" do
      allow(described_class).to receive(:port_available?).with(4567).and_return(false)
      allow(described_class).to receive(:port_available?).with(4568).and_return(true)

      result = described_class.find_available_port

      expect(result).to eq(4568)
    end

    it "returns 4569 when 4567 and 4568 are unavailable but 4569 is available" do
      allow(described_class).to receive(:port_available?).with(4567).and_return(false)
      allow(described_class).to receive(:port_available?).with(4568).and_return(false)
      allow(described_class).to receive(:port_available?).with(4569).and_return(true)

      result = described_class.find_available_port

      expect(result).to eq(4569)
    end

    it "returns a random port between 3000-4000 when 4567-4570 are all unavailable" do
      allow(described_class).to receive(:port_available?).with(4567).and_return(false)
      allow(described_class).to receive(:port_available?).with(4568).and_return(false)
      allow(described_class).to receive(:port_available?).with(4569).and_return(false)
      allow(described_class).to receive(:port_available?).with(4570).and_return(false)
      allow(described_class).to receive(:find_random_port).and_return(3456)

      result = described_class.find_available_port

      expect(result).to eq(3456)
    end

    it "calls find_random_port when default ports are all unavailable" do
      (4567..4570).each do |port|
        allow(described_class).to receive(:port_available?).with(port).and_return(false)
      end

      expect(described_class).to receive(:find_random_port).and_return(3001)

      described_class.find_available_port
    end
  end

  describe ".port_available?" do
    it "returns true when port can be bound" do
      result = described_class.port_available?(12_345)

      expect(result).to be(true)
    end

    it "returns false when port is already in use" do
      skip "Need to implement port binding check"
    end
  end

  describe ".find_random_port" do
    it "returns a port number between 3000 and 4000" do
      result = described_class.find_random_port

      expect(result).to be_between(3000, 4000)
    end
  end
end

# frozen_string_literal: true

require_relative "../../lib/tools"

RSpec.describe Crayons::Tools do
  describe ".new" do
    context "when agent exists" do
      it "returns AgentTool wrapper" do
        tool = described_class.new(:test)

        expect(tool).to be_a(Crayons::Tools::AgentTool)
        expect(tool.name).to eq("TEST")
      end

      it "is case-insensitive" do
        tool1 = described_class.new(:test)
        tool2 = described_class.new(:TEST)
        tool3 = described_class.new(:TeSt)

        expect(tool1.name).to eq("TEST")
        expect(tool2.name).to eq("TEST")
        expect(tool3.name).to eq("TEST")
      end
    end

    context "when tool class exists" do
      it "returns tool instance" do
        tool = described_class.new(:haiku)

        expect(tool).to be_a(Crayons::Tools::Haiku)
        expect(tool.name).to eq("haiku")
      end

      it "returns Bash tool" do
        tool = described_class.new(:bash)

        expect(tool).to be_a(Crayons::Tools::Bash)
      end

      it "returns ReadFile tool" do
        tool = described_class.new(:read_file)

        expect(tool).to be_a(Crayons::Tools::ReadFile)
      end
    end

    context "when neither agent nor tool exists" do
      it "raises ToolNotFoundError" do
        expect { described_class.new(:nonexistent) }.to raise_error(Crayons::ToolNotFoundError)
      end

      it "includes tool name in error message" do
        expect { described_class.new(:ghost) }.to raise_error(/:ghost/)
      end
    end

    context "when agent and tool have same name" do
      it "prioritizes agent over tool" do
        tool = described_class.new(:test)

        expect(tool).to be_a(Crayons::Tools::AgentTool)
        expect(tool.name).to eq("TEST")
      end
    end
  end
end

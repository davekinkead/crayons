# frozen_string_literal: true

require_relative "../../../lib/tools/bash"

RSpec.describe Crayons::Tools::Bash do
  describe "#name" do
    it "returns 'bash'" do
      expect(subject.name).to eq("bash")
    end
  end

  describe "#description" do
    it "returns a description of the tool" do
      expect(subject.description).to be_a(String)
      expect(subject.description).not_to be_empty
    end
  end

  describe "#params" do
    it "returns parameter definitions" do
      expect(subject.params).to be_an(Array)
      expect(subject.params.length).to be >= 1

      command_param = subject.params.find { |p| p[:name] == "command" }
      expect(command_param).not_to be_nil
      expect(command_param[:required]).to be true
    end
  end

  describe "#call" do
    it "executes a command successfully" do
      result = subject.call(command: "echo 'hello world'")

      expect(result[:success]).to be true
      expect(result[:result]).to have_key(:stdout)
      expect(result[:result][:stdout]).to eq("hello world\n")
      expect(result[:result][:stderr]).to eq("")
      expect(result[:result][:exit_status]).to eq(0)
    end

    it "handles command errors" do
      result = subject.call(command: "ls /nonexistent/path")

      expect(result[:success]).to be false
      expect(result[:result]).to have_key(:stderr)
      expect(result[:result][:exit_status]).not_to eq(0)
    end

    it "handles timeout" do
      result = subject.call(command: "sleep 0.2", timeout: 0.1)

      expect(result[:success]).to be false
      expect(result[:result]).to have_key(:error)
    end

    it "requires command parameter" do
      expect { subject.call({}) }.to raise_error(KeyError)
    end
  end
end

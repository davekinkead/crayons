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

  it "forbids rm command" do
    result = tool.execute(command: "rm -rf /tmp/test")
    expect(result[:error]).to include("Forbidden command: rm")
  end

  it "forbids rm command with flags" do
    result = tool.execute(command: "-rm -rf /tmp/test")
    expect(result[:error]).to include("Forbidden command: rm")
  end

  it "forbids rmdir command" do
    result = tool.execute(command: "rmdir /tmp/test")
    expect(result[:error]).to include("Forbidden command: rmdir")
  end

  it "forbids dd command" do
    result = tool.execute(command: "dd if=/dev/zero of=/dev/sda")
    expect(result[:error]).to include("Forbidden command: dd")
  end

  it "forbids mkfs command" do
    result = tool.execute(command: "mkfs.ext4 /dev/sda1")
    expect(result[:error]).to include("Forbidden command: mkfs")
  end

  it "forbids kill command" do
    result = tool.execute(command: "kill -9 1234")
    expect(result[:error]).to include("Forbidden command: kill")
  end

  it "forbids killall command" do
    result = tool.execute(command: "killall ruby")
    expect(result[:error]).to include("Forbidden command: killall")
  end

  it "forbids sudo command" do
    result = tool.execute(command: "sudo rm -rf /")
    expect(result[:error]).to include("Forbidden command: sudo")
  end

  it "forbids su command" do
    result = tool.execute(command: "su root")
    expect(result[:error]).to include("Forbidden command: su")
  end

  it "forbids chmod command" do
    result = tool.execute(command: "chmod 777 /etc/passwd")
    expect(result[:error]).to include("Forbidden command: chmod")
  end

  it "forbids chown command" do
    result = tool.execute(command: "chown root:root /etc/passwd")
    expect(result[:error]).to include("Forbidden command: chown")
  end

  it "forbids apt-get command" do
    result = tool.execute(command: "apt-get install package")
    expect(result[:error]).to include("Forbidden command: apt-get")
  end

  it "forbids yum command" do
    result = tool.execute(command: "yum install package")
    expect(result[:error]).to include("Forbidden command: yum")
  end

  it "forbids brew command" do
    result = tool.execute(command: "brew install package")
    expect(result[:error]).to include("Forbidden command: brew")
  end

  it "forbids mv command" do
    result = tool.execute(command: "mv /etc/passwd /tmp/passwd")
    expect(result[:error]).to include("Forbidden command: mv")
  end

  it "forbids cp command" do
    result = tool.execute(command: "cp /etc/passwd /tmp/passwd")
    expect(result[:error]).to include("Forbidden command: cp")
  end

  it "forbids dangerous commands in pipe chain" do
    result = tool.execute(command: "cat file.txt | rm /tmp/test")
    expect(result[:error]).to include("Forbidden command: rm")
  end

  it "forbids rm -rf / pattern specifically" do
    result = tool.execute(command: "rm -rf /")
    expect(result[:error]).to include("Forbidden command pattern detected")
  end

  it "forbids rm -rf /* pattern specifically" do
    result = tool.execute(command: "rm -rf /*")
    expect(result[:error]).to include("Forbidden command pattern detected")
  end

  it "forbids dd if=/dev/zero pattern specifically" do
    result = tool.execute(command: "dd if=/dev/zero of=/dev/sda")
    # Either pattern or command error is acceptable since dd is blocked
    expect(result[:error]).to match(/Forbidden/)
  end

  it "allows safe commands like echo" do
    result = tool.execute(command: 'echo "test"')
    expect(result[:output]).to include("test")
    expect(result[:exit_status]).to eq(0)
  end

  it "allows safe commands like ls" do
    result = tool.execute(command: "ls -la")
    expect(result[:exit_status]).to eq(0)
  end

  it "allows safe commands like cat" do
    result = tool.execute(command: "cat README.md")
    expect(result[:exit_status]).to eq(0)
  end

  it "allows safe commands like grep" do
    result = tool.execute(command: "grep 'test' README.md")
    expect(result[:exit_status]).to eq(0)
  end

  it "allows safe commands like find" do
    result = tool.execute(command: "find . -name '*.rb'")
    expect(result[:exit_status]).to eq(0)
  end

  it "allows git commands" do
    result = tool.execute(command: "git status")
    expect(result[:exit_status]).to eq(0)
  end

  it "allows ruby commands" do
    result = tool.execute(command: "ruby -v")
    expect(result[:exit_status]).to eq(0)
  end

  it "allows rspec commands" do
    result = tool.execute(command: "rspec --version")
    expect(result[:exit_status]).to eq(0)
  end
end

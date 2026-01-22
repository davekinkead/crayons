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

  # Tests for refined rm behavior - allow without recursive flags
  it "allows rm without recursive flags" do
    result = tool.execute(command: "rm /tmp/nonexistent_test_file_12345")
    # Command will fail because file doesn't exist, but should not be blocked by sanitizer
    expect(result[:error]).to be_nil
  end

  it "blocks rm with -r flag" do
    result = tool.execute(command: "rm -r /tmp/test")
    expect(result[:error]).to include("recursive")
  end

  it "blocks rm with -rf flag" do
    result = tool.execute(command: "rm -rf /tmp/test")
    expect(result[:error]).to include("recursive")
  end

  it "blocks rm with -R flag" do
    result = tool.execute(command: "rm -R /tmp/test")
    expect(result[:error]).to include("recursive")
  end

  it "blocks rm with -fr flag" do
    result = tool.execute(command: "rm -fr /tmp/test")
    expect(result[:error]).to include("recursive")
  end

  it "blocks rm -rf / pattern specifically" do
    result = tool.execute(command: "rm -rf /")
    expect(result[:error]).to include("Forbidden command pattern")
  end

  it "blocks rm -rf /* pattern specifically" do
    result = tool.execute(command: "rm -rf /*")
    expect(result[:error]).to include("Forbidden command pattern")
  end

  # Tests for newly allowed commands
  it "allows cp command" do
    result = tool.execute(command: "cp /tmp/nonexistent_src /tmp/nonexistent_dest")
    # Command will fail but should not be blocked
    expect(result[:error]).to be_nil
  end

  it "allows mv command" do
    result = tool.execute(command: "mv /tmp/nonexistent_src /tmp/nonexistent_dest")
    # Command will fail but should not be blocked
    expect(result[:error]).to be_nil
  end

  it "allows brew command" do
    result = tool.execute(command: "brew list")
    # brew list should work if brew is installed, otherwise fails but not blocked
    expect(result[:error]).to be_nil
  end

  it "allows wget command" do
    result = tool.execute(command: "wget --help")
    # wget --help should work if wget is installed
    expect(result[:error]).to be_nil
  end

  it "allows curl command" do
    result = tool.execute(command: "curl --version")
    # curl --version should work
    expect(result[:error]).to be_nil
  end

  # Tests for still-blocked dangerous commands
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

  it "forbids dnf command" do
    result = tool.execute(command: "dnf install package")
    expect(result[:error]).to include("Forbidden command: dnf")
  end

  it "forbids pacman command" do
    result = tool.execute(command: "pacman -S package")
    expect(result[:error]).to include("Forbidden command: pacman")
  end

  it "forbids shutdown command" do
    result = tool.execute(command: "shutdown -h now")
    expect(result[:error]).to include("Forbidden command: shutdown")
  end

  it "forbids reboot command" do
    result = tool.execute(command: "reboot")
    expect(result[:error]).to include("Forbidden command: reboot")
  end

  it "forbids dangerous commands in pipe chain" do
    result = tool.execute(command: "cat README.md | rm -rf /tmp/test")
    expect(result[:error]).to include("recursive")
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
    result = tool.execute(command: "grep 'Crayons' README.md")
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

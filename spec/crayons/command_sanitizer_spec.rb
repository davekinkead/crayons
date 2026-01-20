# frozen_string_literal: true
require "spec_helper"
require_relative "../../lib/crayons"

RSpec.describe Crayons::CommandSanitizer do
  describe ".validate" do
    it "returns nil for safe commands" do
      expect(described_class.validate("echo hello")).to be_nil
      expect(described_class.validate("ls -la")).to be_nil
      expect(described_class.validate("cat file.txt")).to be_nil
    end

    it "blocks dangerous commands" do
      expect(described_class.validate("dd if=/dev/zero of=/dev/sda")).to include("Forbidden command")
      expect(described_class.validate("mkfs.ext4 /dev/sda1")).to include("Forbidden command")
      expect(described_class.validate("kill -9 1234")).to include("Forbidden command")
      expect(described_class.validate("killall ruby")).to include("Forbidden command")
    end

    it "allows cp command" do
      expect(described_class.validate("cp file1.txt file2.txt")).to be_nil
      expect(described_class.validate("cp -r dir1 dir2")).to be_nil
    end

    it "allows mv command" do
      expect(described_class.validate("mv file1.txt file2.txt")).to be_nil
    end

    it "allows brew command" do
      expect(described_class.validate("brew install package")).to be_nil
      expect(described_class.validate("brew list")).to be_nil
    end

    it "allows wget command" do
      expect(described_class.validate("wget https://example.com/file")).to be_nil
    end

    it "allows curl command" do
      expect(described_class.validate("curl https://example.com")).to be_nil
    end

    it "allows rm without recursive flags" do
      expect(described_class.validate("rm /tmp/test")).to be_nil
      expect(described_class.validate("rm -f /tmp/test")).to be_nil
      expect(described_class.validate("rm -i /tmp/test")).to be_nil
    end

    it "blocks rm with recursive flags" do
      expect(described_class.validate("rm -r /tmp/test")).to include("recursive")
      expect(described_class.validate("rm -rf /tmp/test")).to include("recursive")
      expect(described_class.validate("rm -R /tmp/test")).to include("recursive")
      expect(described_class.validate("rm -rR /tmp/test")).to include("recursive")
      expect(described_class.validate("rm -fr /tmp/test")).to include("recursive")
    end

    it "blocks sudo command" do
      expect(described_class.validate("sudo rm -rf /")).to include("Forbidden command")
    end

    it "blocks su command" do
      expect(described_class.validate("su root")).to include("Forbidden command")
    end

    it "blocks chmod command" do
      expect(described_class.validate("chmod 777 /etc/passwd")).to include("Forbidden command")
    end

    it "blocks chown command" do
      expect(described_class.validate("chown root:root /etc/passwd")).to include("Forbidden command")
    end

    it "blocks apt-get command" do
      expect(described_class.validate("apt-get install package")).to include("Forbidden command")
    end

    it "blocks yum command" do
      expect(described_class.validate("yum install package")).to include("Forbidden command")
    end

    it "blocks dnf command" do
      expect(described_class.validate("dnf install package")).to include("Forbidden command")
    end

    it "blocks pacman command" do
      expect(described_class.validate("pacman -S package")).to include("Forbidden command")
    end

    it "blocks shutdown command" do
      expect(described_class.validate("shutdown -h now")).to include("Forbidden command")
    end

    it "blocks reboot command" do
      expect(described_class.validate("reboot")).to include("Forbidden command")
    end

    it "blocks rm -rf / pattern specifically" do
      expect(described_class.validate("rm -rf /")).to include("Forbidden command pattern")
    end

    it "blocks rm -rf /* pattern specifically" do
      expect(described_class.validate("rm -rf /*")).to include("Forbidden command pattern")
    end
  end

  describe ".check_unsafe_operators" do
    it "returns nil for commands without unsafe operators" do
      expect(described_class.check_unsafe_operators("ls -la")).to be_nil
      expect(described_class.validate("echo hello")).to be_nil
    end

    it "detects semicolon" do
      expect(described_class.check_unsafe_operators("ls; rm -rf /")).to include("unsafe operators")
    end

    it "detects ampersand" do
      expect(described_class.check_unsafe_operators("ls & rm -rf /")).to include("unsafe operators")
    end

    it "detects backticks" do
      expect(described_class.check_unsafe_operators("echo `rm -rf /`")).to include("unsafe operators")
    end

    it "detects dollar sign substitution" do
      expect(described_class.check_unsafe_operators("echo $(rm -rf /)")).to include("unsafe operators")
    end

    it "detects parentheses" do
      expect(described_class.check_unsafe_operators("echo (rm -rf /)")).to include("unsafe operators")
    end
  end

  describe ".check_output_redirection" do
    it "returns nil for commands without output redirection" do
      expect(described_class.check_output_redirection("ls -la")).to be_nil
    end

    it "detects output redirection" do
      expect(described_class.check_output_redirection("ls > /tmp/output")).to include("output redirection")
    end

    it "allows grep with pipe (not output redirection)" do
      expect(described_class.check_output_redirection("ls | grep test")).to be_nil
    end
  end

  describe ".check_pipe_command" do
    it "returns nil for allowed pipe commands" do
      allowed = %w[head tail sort uniq wc grep cut sed]
      expect(described_class.check_pipe_command("head -n 5", allowed)).to be_nil
      expect(described_class.check_pipe_command("tail -n 5", allowed)).to be_nil
      expect(described_class.check_pipe_command("sort", allowed)).to be_nil
      expect(described_class.check_pipe_command("uniq", allowed)).to be_nil
      expect(described_class.check_pipe_command("wc -l", allowed)).to be_nil
      expect(described_class.check_pipe_command("grep test", allowed)).to be_nil
      expect(described_class.check_pipe_command("cut -d: -f1", allowed)).to be_nil
      expect(described_class.check_pipe_command("sed s/foo/bar/g", allowed)).to be_nil
    end

    it "returns nil when no allowed_commands list is provided" do
      expect(described_class.check_pipe_command("rm /tmp/file", [])).to be_nil
      expect(described_class.check_pipe_command("dd if=/dev/zero", [])).to be_nil
    end

    it "detects disallowed pipe commands when allowed list is provided" do
      allowed = %w[head tail sort uniq wc grep]
      expect(described_class.check_pipe_command("rm /tmp/file", allowed)).to include("not allowed")
      expect(described_class.check_pipe_command("dd if=/dev/zero", allowed)).to include("not allowed")
    end
  end
end

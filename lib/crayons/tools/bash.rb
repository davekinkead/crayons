# frozen_string_literal: true
require "english"
module Crayons
  class BashTool < Tool
    description "Execute bash commands in the project directory"

    params do
      string :command, description: "The bash command to execute"
    end

    DANGEROUS_COMMANDS = %w[
      rm rmdir dd mkfs format fdisk shred wipe
      kill killall pkill shutdown reboot halt poweroff
      sudo su chown chmod chgrp
      apt apt-get yum dnf pacman brew
      mv cp
    ].freeze

    def execute(command:)
      error = validate_command(command)
      return { error: error } if error

      output = `#{command} 2>&1`
      exit_status = $CHILD_STATUS.exitstatus

      { output: output, exit_status: exit_status }
    rescue StandardError => e
      { error: e.message }
    end

    private

    def validate_command(command)
      # Check for dangerous patterns first (be more specific)
      return "Forbidden command pattern detected." if command =~ %r{^rm -rf /$} || command =~ %r{^rm -rf /\*$}

      # Check for dangerous commands at the start of any pipe chain
      command_parts = command.split("|").map(&:strip)

      command_parts.each do |part|
        first_word = part.split(/\s+/).first
        first_word_no_flags = first_word.to_s.gsub(/^-+/, "")

        # Check against dangerous command list
        DANGEROUS_COMMANDS.each do |dangerous|
          if first_word_no_flags == dangerous ||
             first_word_no_flags.start_with?("#{dangerous}.") ||
             first_word_no_flags.start_with?("#{dangerous} ")
            return "Forbidden command: #{dangerous}. This command is not allowed."
          end
        end
      end

      nil
    end
  end
end

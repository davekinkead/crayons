# frozen_string_literal: true

module Crayons
  # CommandSanitizer provides reusable validation logic for shell commands
  # Used by BashTool, GrepTool, and GlobTool to ensure command safety
  module CommandSanitizer
    # Dangerous commands that are completely blocked
    DANGEROUS_COMMANDS = %w[
      rmdir dd mkfs format fdisk shred wipe
      kill killall pkill shutdown reboot halt poweroff
      sudo su chown chmod chgrp
      apt apt-get yum dnf pacman
    ].freeze

    # Allowed pipe commands for GrepTool
    GREP_ALLOWED_PIPE_COMMANDS = %w[head tail sort uniq wc grep cut sed].freeze

    # Allowed pipe commands for GlobTool
    GLOB_ALLOWED_PIPE_COMMANDS = %w[head tail sort uniq wc xargs].freeze

    # Regex patterns for detecting unsafe operators
    UNSAFE_OPERATOR_PATTERN = /[;&`$()]/
    OUTPUT_REDIRECTION_PATTERN = />[^>]/

    class << self
      # Validate a command and return an error message if unsafe, or nil if safe
      def validate(command)
        # Check for dangerous patterns first
        dangerous_pattern_error = check_dangerous_patterns(command)
        return dangerous_pattern_error if dangerous_pattern_error

        # Check for dangerous commands in all pipe chains
        command_parts = command.split("|").map(&:strip)

        command_parts.each do |part|
          error = check_command_part(part)
          return error if error
        end

        nil
      end

      # Check for unsafe operators (;, &, backticks, $, or parentheses)
      def check_unsafe_operators(command)
        return "Command contains unsafe operators (;, &, backticks, $, or parentheses)" if command.match?(UNSAFE_OPERATOR_PATTERN)
        nil
      end

      # Check for output redirection
      def check_output_redirection(command)
        return "Command contains output redirection (>)" if command.match?(OUTPUT_REDIRECTION_PATTERN)
        nil
      end

      # Check if a piped command is allowed
      # @param piped_command [String] The command after the pipe
      # @param allowed_commands [Array<String>] List of allowed command names
      def check_pipe_command(piped_command, allowed_commands = [])
        return nil if allowed_commands.empty?

        piped_cmd_name = piped_command.split.first
        return "Piped command '#{piped_cmd_name}' is not allowed. Allowed: #{allowed_commands.join(', ')}" unless allowed_commands.include?(piped_cmd_name)

        return "Piped command contains unsafe operators" if piped_command.match?(UNSAFE_OPERATOR_PATTERN) || piped_command.match?(OUTPUT_REDIRECTION_PATTERN)

        nil
      end

      # Check if rm command has recursive flags
      def has_recursive_flag?(command)
        # Match -r or -R with optional following letters (like -rf, -fr, -rR)
        !!(command =~ /-[fFrR]*[rR]/)
      end

      private

      # Check for specific dangerous command patterns
      def check_dangerous_patterns(command)
        return "Forbidden command pattern detected." if command =~ %r{^rm -rf /$} || command =~ %r{^rm -rf /\*$}
        nil
      end

      # Check a single command part (before or after a pipe)
      def check_command_part(part)
        first_word = part.split(/\s+/).first
        return nil unless first_word

        first_word_no_flags = first_word.to_s.gsub(/^-+/, "")

        # Special handling for rm: allow without recursive flags
        return "rm command is not allowed with recursive flags (-r, -rf, -R, -fr, etc.)." if first_word_no_flags == "rm" && has_recursive_flag?(part)

        # Check against dangerous command list
        DANGEROUS_COMMANDS.each do |dangerous|
          if first_word_no_flags == dangerous ||
             first_word_no_flags.start_with?("#{dangerous}.") ||
             first_word_no_flags.start_with?("#{dangerous} ")
            return "Forbidden command: #{dangerous}. This command is not allowed."
          end
        end

        nil
      end
    end
  end
end

# frozen_string_literal: true
require "english"
module Crayons
  class GrepTool < Tool
    description "Execute ripgrep commands (rg) to search for patterns in files"

    params do
      string :command, description: "The ripgrep command to execute (must start with 'rg')"
    end

    def execute(command:)
      return { error: "Command must start with 'rg'", matches: [] } unless command.strip.start_with?("rg")

      error = unsafe_command?(command)
      return { error: error, matches: [] } if error

      output = `#{command} 2>&1`
      exit_status = $CHILD_STATUS.exitstatus

      matches = parse_rg_output(output)
      { output: output, exit_status: exit_status, matches: matches }
    rescue StandardError => e
      { error: e.message, matches: [] }
    end

    private

    def unsafe_command?(command)
      error = CommandSanitizer.check_unsafe_operators(command)
      return error if error

      error = CommandSanitizer.check_output_redirection(command)
      return error if error

      if command.match?(/\|[^|]/)
        piped_command = command.split("|", 2)[1].strip
        allowed_pipe_commands = CommandSanitizer::GREP_ALLOWED_PIPE_COMMANDS
        return CommandSanitizer.check_pipe_command(piped_command, allowed_pipe_commands)
      end

      false
    end

    def parse_rg_output(output)
      return [] if output.empty?

      output.split("\n").map do |line|
        match = line.match(/^([^:]+):(\d+):(.*)$/)
        next unless match
        {
          file: match[1],
          line_number: match[2].to_i,
          content: match[3]
        }
      end.compact
    end
  end
end

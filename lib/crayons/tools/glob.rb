# frozen_string_literal: true
require "english"
module Crayons
  class GlobTool < Tool
    description "Execute find commands to locate files"

    params do
      string :command, description: "The find command to execute (must start with 'find')"
    end

    def execute(command:)
      return { error: "Command must start with 'find'", files: [] } unless command.strip.start_with?("find")

      error = unsafe_command?(command)
      return { error: error, files: [] } if error

      output = `#{command} 2>&1`
      exit_status = $CHILD_STATUS.exitstatus

      files = output.split("\n").map(&:strip).reject(&:empty?)
      { output: output, exit_status: exit_status, files: files }
    rescue StandardError => e
      { error: e.message, files: [] }
    end

    private

    def unsafe_command?(command)
      error = CommandSanitizer.check_unsafe_operators(command)
      return error if error

      error = CommandSanitizer.check_output_redirection(command)
      return error if error

      if command.match?(/\|/)
        piped_command = command.split("|", 2)[1].strip
        allowed_pipe_commands = CommandSanitizer::GLOB_ALLOWED_PIPE_COMMANDS
        return CommandSanitizer.check_pipe_command(piped_command, allowed_pipe_commands)
      end

      false
    end
  end
end

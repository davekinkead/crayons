# frozen_string_literal: true
require "English"
module Crayons
  class GlobTool < Tool
    description "Execute find commands to locate files"

    params do
      string :command, description: "The find command to execute (must start with 'find')"
    end

    # Simply pass it on to bash if it is safe to do so
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
      return "Command contains unsafe operators (;, &, backticks, $, or parentheses)" if command.match?(/[;&`$()]/)

      return "Command contains output redirection" if command.match?(/>/)

      if command.match?(/\|/)
        piped_command = command.split("|", 2)[1].strip
        allowed_pipe_commands = %w[head tail sort uniq wc xargs]
        piped_cmd_name = piped_command.split.first

        return "Piped command '#{piped_cmd_name}' is not allowed. Allowed: #{allowed_pipe_commands.join(', ')}" unless allowed_pipe_commands.include?(piped_cmd_name)

        return "Piped command contains unsafe operators" if unsafe_command_in_pipe?(piped_command)
      end

      false
    end

    def unsafe_command_in_pipe?(piped_command)
      piped_command.match?(/[;&`$()]/) || piped_command.match?(/>/)
    end
  end
end

module Ralph
  class GrepTool < Tool
    description "Execute ripgrep commands (rg) to search for patterns in files"

    params do
      string :command, description: "The ripgrep command to execute (must start with 'rg')"
    end

    # Simply pass it on to bash if it is safe to do so
    def execute(command:)
      return { error: "Command must start with 'rg'", matches: [] } unless command.strip.start_with?('rg')

      error = unsafe_command?(command)
      return { error: error, matches: [] } if error

      output = `#{command} 2>&1`
      exit_status = $?.exitstatus

      matches = parse_rg_output(output)
      { output: output, exit_status: exit_status, matches: matches }
    rescue => e
      { error: e.message, matches: [] }
    end

    private

    def unsafe_command?(command)
      if command.match?(/[;&`$\(\)]/)
        return "Command contains unsafe operators (;, &, backticks, $, or parentheses)"
      end

      if command.match?(/>[^>]/)
        return "Command contains unsafe output redirection (>)"
      end

      if command.match?(/\|[^|]/)
        piped_command = command.split('|', 2)[1].strip
        allowed_pipe_commands = ['head', 'tail', 'sort', 'uniq', 'wc', 'grep', 'cut', 'awk', 'sed']
        piped_cmd_name = piped_command.split.first

        unless allowed_pipe_commands.include?(piped_cmd_name)
          return "Piped command '#{piped_cmd_name}' is not allowed. Allowed: #{allowed_pipe_commands.join(', ')}"
        end

        if unsafe_command_in_pipe?(piped_command)
          return "Piped command contains unsafe operators"
        end
      end

      nil
    end

    def unsafe_command_in_pipe?(piped_command)
      piped_command.match?(/[;&`$\(\)]/) || piped_command.match?(/>[^>]/)
    end

    def parse_rg_output(output)
      return [] if output.empty?

      output.split("\n").map do |line|
        match = line.match(/^([^:]+):(\d+):(.*)$/)
        if match
          {
            file: match[1],
            line_number: match[2].to_i,
            content: match[3]
          }
        else
          nil
        end
      end.compact
    end
  end
end

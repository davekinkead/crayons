module Ralph
  class BashTool < RubyLLM::Tool
    description "Execute bash commands in the project directory"

    params do
      string :command, description: "The bash command to execute"
    end

    def execute(command:)
      output = `#{command} 2>&1`
      exit_status = $?.exitstatus

      { output: output, exit_status: exit_status }
    rescue => e
      { error: e.message }
    end
  end
end

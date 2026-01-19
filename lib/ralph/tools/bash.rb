# frozen_string_literal: true
require "English"
module Ralph
  class BashTool < Tool
    description "Execute bash commands in the project directory"

    params do
      string :command, description: "The bash command to execute"
    end

    def execute(command:)
      output = `#{command} 2>&1`
      exit_status = $CHILD_STATUS.exitstatus

      { output: output, exit_status: exit_status }
    rescue StandardError => e
      { error: e.message }
    end
  end
end

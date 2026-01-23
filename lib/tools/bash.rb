# frozen_string_literal: true

require_relative "../tool"

module Crayons
  module Tools
    class Bash < Crayons::Tool
      def name = "bash"

      def description = "Execute shell commands and capture output"

      def params
        [
          { name: "command", description: "The shell command to execute", required: true },
          { name: "timeout", description: "Maximum execution time in seconds", required: false }
        ]
      end

      def call(input)
        command = input[:command]
        timeout = input[:timeout] || 120

        raise KeyError, "command is required" if command.nil?

        require "open3"
        require "timeout"

        ::Timeout.timeout(timeout) do
          result = Open3.popen3(command) do |stdin, stdout, stderr, wait_thread|
            stdin.close

            begin
              stdout_data = stdout.read
              stderr_data = stderr.read
              exit_status = wait_thread.value.exitstatus

              {
                success: exit_status.zero?,
                result: {
                  stdout: stdout_data,
                  stderr: stderr_data,
                  exit_status: exit_status
                }
              }
            rescue Errno::ENOENT => e
              {
                success: false,
                result: { error: e.message, exit_status: 127 }
              }
            end
          end

          result
        end
      rescue ::Timeout::Error
        { success: false, result: { error: "Command timed out", exit_status: nil } }
      end
    end
  end
end

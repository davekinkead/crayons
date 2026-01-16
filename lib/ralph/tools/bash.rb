require 'open3'
require 'timeout'

module Ralph
  module Tools
    class Bash
      DANGEROUS_COMMANDS = %w[rm dd mkfs shred format fdisk :> > >>]

      def self.run(command, timeout: 120_000)
        sanitize!(command)

        Timeout.timeout(timeout / 1000.0) do
          stdout, stderr, status = Open3.capture3(command)

          {
            success: status.success?,
            exit_code: status.exitstatus,
            stdout:,
            stderr:
          }
        end
      rescue Timeout::Error
        {
          success: false,
          exit_code: nil,
          stdout: '',
          stderr: "Command timed out after #{timeout}ms"
        }
      rescue RuntimeError => e
        {
          success: false,
          exit_code: nil,
          stdout: '',
          stderr: e.message
        }
      end

      def self.sanitize!(command)
        DANGEROUS_COMMANDS.each do |dangerous|
          raise "Dangerous command blocked: #{dangerous}" if command.include?(dangerous)
        end
      end
    end
  end
end

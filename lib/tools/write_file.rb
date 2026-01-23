# frozen_string_literal: true

require_relative "../tool"

module Crayons
  module Tools
    class WriteFile < Crayons::Tool
      def name = "write_file"

      def description = "Write content to a file, creating or overwriting it"

      def params
        [
          { name: "filepath", description: "The absolute path to the file to write", required: true },
          { name: "content", description: "The content to write to the file", required: true }
        ]
      end

      def call(input)
        filepath = input[:filepath]
        content = input[:content]

        raise KeyError, "filepath is required" if filepath.nil?
        raise KeyError, "content is required" if content.nil?

        File.write(filepath, content)

        {
          success: true,
          result: { filepath: filepath, bytes_written: content.bytesize }
        }
      rescue Errno::EACCES => e
        { success: false, result: { error: "Permission denied: #{e.message}" } }
      rescue Errno::ENOENT => e
        { success: false, result: { error: "Directory not found: #{e.message}" } }
      rescue SystemCallError => e
        { success: false, result: { error: e.message } }
      end
    end
  end
end

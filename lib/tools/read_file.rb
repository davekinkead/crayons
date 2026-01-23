# frozen_string_literal: true

require_relative "../tool"

module Crayons
  module Tools
    class ReadFile < Crayons::Tool
      def name = "read_file"

      def description = "Read file contents from a given filepath"

      def params
        [
          { name: "filepath", description: "The absolute path to the file to read", required: true }
        ]
      end

      def call(input)
        filepath = input[:filepath]

        raise KeyError, "filepath is required" if filepath.nil?

        return { success: false, result: { error: "File not found: #{filepath}" } } unless File.exist?(filepath)
        return { success: false, result: { error: "Path is not a file: #{filepath}" } } unless File.file?(filepath)

        content = File.read(filepath)

        {
          success: true,
          result: { content: content, filepath: filepath }
        }
      rescue Errno::EACCES => e
        { success: false, result: { error: "Permission denied: #{e.message}" } }
      rescue SystemCallError => e
        { success: false, result: { error: e.message } }
      end
    end
  end
end

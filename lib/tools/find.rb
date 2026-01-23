# frozen_string_literal: true

require "open3"
require "shellwords"
require_relative "../tool"

module Crayons
  module Tools
    class Find < Crayons::Tool
      attr_reader :dir

      def name = "find"

      def description = "Find files matching a pattern"

      def params
        [
          { name: "pattern", description: "The glob pattern to match files against", required: true },
          { name: "path", description: "The directory to search in. Defaults to current directory", required: false }
        ]
      end

      def call(input)
        pattern = input[:pattern]
        @dir = input[:path] || Dir.pwd

        raise KeyError, "pattern is required" if pattern.nil?

        return { success: false, result: { error: "Directory not found: #{@dir}" } } unless Dir.exist?(@dir)
        return { success: false, result: { error: "Path is not a directory: #{@dir}" } } unless File.directory?(@dir)

        escaped_path = Shellwords.escape(@dir)
        command = "find #{escaped_path} -type f -name #{Shellwords.escape(pattern)} | sort"

        stdout, stderr, status = Open3.capture3(command)

        matches = stdout.strip.split("\n").reject(&:empty?)

        if status.success?
          {
            success: true,
            result: { matches: matches, pattern: pattern, path: @dir }
          }
        else
          { success: false, result: { error: stderr.strip } }
        end
      rescue SystemCallError => e
        { success: false, result: { error: e.message } }
      end
    end
  end
end

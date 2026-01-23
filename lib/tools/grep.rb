# frozen_string_literal: true

require "open3"
require_relative "../tool"

module Crayons
  module Tools
    class Grep < Crayons::Tool
      attr_reader :dir

      def name = "grep"

      def description = "Search file contents using regex patterns"

      def params
        [
          { name: "pattern", description: "The regex pattern to search for", required: true },
          { name: "path", description: "The directory to search in. Defaults to current directory", required: false },
          { name: "include", description: "File pattern to include in search (e.g., '*.rb')", required: false }
        ]
      end

      def call(input)
        @dir = input[:path] || Dir.pwd
        pattern = input[:pattern]
        include_pattern = input[:include]

        raise KeyError, "pattern is required" if pattern.nil?

        return { success: false, result: { error: "Directory not found: #{@dir}" } } unless Dir.exist?(@dir)
        return { success: false, result: { error: "Path is not a directory: #{@dir}" } } unless File.directory?(@dir)

        escaped_path = Shellwords.escape(@dir)
        escaped_pattern = Shellwords.escape(pattern)

        command = if include_pattern
          escaped_include = Shellwords.escape(include_pattern)
          "grep -rn #{escaped_pattern} #{escaped_path} --include=#{escaped_include}"
        else
          "grep -rn #{escaped_pattern} #{escaped_path}"
        end

        stdout, = Open3.capture3(command)

        matches = stdout.strip.split("\n").reject(&:empty?).sort

        {
          success: true,
          result: { matches: matches, pattern: pattern, path: @dir, include: include_pattern }
        }
      rescue SystemCallError => e
        { success: false, result: { error: e.message } }
      end
    end
  end
end

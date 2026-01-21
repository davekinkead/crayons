# frozen_string_literal: true
module Crayons
  class ReadFileTool < Tool
    description "Read the contents of a file"

    params do
      string :file_path, description: "The absolute path to the file(s) to read. Can be a single file path or an array of file paths"
    end

    def execute(file_path:)
      if file_path.is_a?(Array)
        read_multiple_files(file_path)
      else
        read_single_file(file_path)
      end
    end

    private

    # FIX: Make both return the same shape ...
    # { success: true/false, files: [{ path: "...", content: "..." }] }
    def read_single_file(path)
      return { error: "File not found: #{path}", success: false } unless File.exist?(path)

      content = File.read(path)
      { content: content, file_path: path, success: true }
    rescue StandardError => e
      { error: e.message, success: false }
    end

    def read_multiple_files(paths)
      paths.each_with_object({}) do |path, results|
        results[path] = read_single_file(path)
      end
    end
  end
end

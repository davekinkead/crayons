# frozen_string_literal: true
module Crayons
  class WriteFileTool < Tool
    description "Write content to a file (overwrites existing content)"

    params do
      string :file_path, description: "The absolute path to the file to write"
      string :content, description: "The content to write to the file"
    end

    def execute(file_path:, content:)
      File.write(file_path, content)
      { success: true, file_path: file_path, bytes_written: content.bytesize }
    rescue StandardError => e
      { error: e.message, success: false }
    end
  end
end

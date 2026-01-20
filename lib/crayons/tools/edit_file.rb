# frozen_string_literal: true
module Crayons
  class EditFileTool < Tool
    description "Edit a file by replacing old_string with new_string"

    params do
      string :file_path, description: "The absolute path to the file to edit"
      string :old_string, description: "The exact string to find and replace"
      string :new_string, description: "The new string to replace it with"
    end

    def execute(file_path:, old_string:, new_string:)
      return { error: "File not found: #{file_path}", success: false } unless File.exist?(file_path)

      content = File.read(file_path)
      
      return { error: "String not found in file", success: false } unless content.include?(old_string)

      return { error: "String found multiple times - use replace_all parameter", success: false } if content.scan(old_string).length > 1

      new_content = content.sub(old_string, new_string)
      File.write(file_path, new_content)
      
      { success: true, file_path: file_path }
    rescue StandardError => e
      { error: e.message, success: false }
    end
  end
end

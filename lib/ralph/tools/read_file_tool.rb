module Ralph
  class ReadFileTool < RubyLLM::Tool
    description "Read the contents of a file"

    params do
      string :file_path, description: "The absolute path to the file to read"
    end

    def execute(file_path:)
      unless File.exist?(file_path)
        return { error: "File not found: #{file_path}" }
      end

      content = File.read(file_path)
      { content: content, file_path: file_path, success: true }
    rescue => e
      { error: e.message, success: false }
    end
  end
end

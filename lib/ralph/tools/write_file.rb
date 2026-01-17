require_relative '../tool'

class Ralph::Tools::WriteFile < Ralph::Tool
  description 'Write content to a file'
  param :path, type: 'string', description: 'The path to the file to write'
  param :content, type: 'string', description: 'The content to write to the file'

  class << self
    def write(path, content)
      new.write(path:, content: content)
    end
  end

  def call(path:, content:)
    File.write(path, content)
  end
end

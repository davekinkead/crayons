require_relative '../tool'

class Ralph::Tools::ReadFile < Ralph::Tool
  description 'Read the contents of a file'
  param :path, type: 'string', description: 'The path to the file to read', required: true

  class << self
    def read(path)
      new.call(path:)
    end
  end

  def call(path:)
    File.read(path)
  end
end

require_relative '../tool'

class Ralph::Tools::EditFile < Ralph::Tool
  description 'Edit a file by replacing text'
  param :path, type: 'string', description: 'The path to the file to edit'
  param :old_string, type: 'string', description: 'The text to replace'
  param :new_string, type: 'string', description: 'The replacement text'
  param :replace_all, type: 'boolean', description: 'Replace all occurrences', required: false

  class << self
    def edit(path, old_string, new_string, replace_all: false)
      new.edit(path:, old_string:, new_string:, replace_all:)
    end
  end

  def call(path:, old_string:, new_string:, replace_all: false)
    content = File.read(path)

    raise 'old_string not found in file' unless content.include?(old_string)

    if !replace_all && content.scan(old_string).size > 1
      raise 'old_string found multiple times, use replace_all: true or provide more context'
    end

    new_content = replace_all ? content.gsub(old_string, new_string) : content.sub(old_string, new_string)
    File.write(path, new_content)
  end
end

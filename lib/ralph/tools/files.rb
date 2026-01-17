require_relative '../tool'

module Ralph
  module Tools
    class Files < Ralph::Tool
      class << self
        def read(path)
          new.read(path:)
        end

        def write(path, content)
          new.write(path:, content:)
        end

        def edit(path, old_string, new_string, replace_all: false)
          new.edit(path:, old_string:, new_string:, replace_all:)
        end
      end

      def read(path:)
        File.read(path)
      end

      def write(path:, content:)
        File.write(path, content)
      end

      def edit(path:, old_string:, new_string:, replace_all: false)
        content = read(path:)

        raise 'old_string not found in file' unless content.include?(old_string)

        if !replace_all && content.scan(old_string).size > 1
          raise 'old_string found multiple times, use replace_all: true or provide more context'
        end

        new_content = replace_all ? content.gsub(old_string, new_string) : content.sub(old_string, new_string)
        write(path:, content: new_content)
      end
    end
  end
end

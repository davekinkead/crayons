require 'yaml'

module Ralph
  module Agents
    class Base
      attr_reader :name, :config, :context

      def initialize(agent_path)
        @agent_path = agent_path
        @config = parse_frontmatter(agent_path)
        @name = @config['name']
        @context = {}
      end

      private

      def parse_frontmatter(path)
        content = File.read(path)
        match = content.match(/^---$(.*?)^---$/m)
        return {} unless match

        YAML.load(match[1])
      end
    end
  end
end

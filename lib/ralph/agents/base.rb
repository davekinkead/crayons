require 'yaml'
require_relative '../clients/openai'

module Ralph
  module Agents
    class Base
      attr_reader :name, :config, :context, :client, :messages

      def initialize(agent_path, client:)
        @agent_path = agent_path
        @config = parse_frontmatter(agent_path)
        @name = @config['name']
        @context = {}
        @client = client
        @messages = []
      end

      def chat(role, content)
        @messages << { role:, content: }
        @client.chat(messages: @messages)
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

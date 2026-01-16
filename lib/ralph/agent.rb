require_relative 'agents/base'
require 'yaml'

module Ralph
  class Agent < Agents::Base
    class << self
      def new(name)
        path = find_agent_file(name)
        super(path)
      end

      private

      def find_agent_file(name)
        path = File.join('agents', "#{name.upcase}.md")
        raise Ralph::Error, "Agent file not found: #{path}" unless File.exist?(path)

        path
      end
    end
  end
end

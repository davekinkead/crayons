module Ralph
  class Agent
    attr_reader :name, :description, :tools, :instructions

    def initialize(agent_name, agents_dir:)
      agent_file = File.join(agents_dir, "#{agent_name}.md")
      raise "Agent file not found: #{agent_file}" unless File.exist?(agent_file)

      load_agent_config(agent_file)
    end

    def call(prompt)
      chat = Ralph::Client.new.chat
      
      chat.ask "#{@instructions}\n\n#{prompt}"
    end

    private

    def load_agent_config(file_path)
      content = File.read(file_path)
      frontmatter, body = parse_frontmatter(content)

      @name = frontmatter['name']
      @description = frontmatter['description']
      @tools = Array(frontmatter['tools'])
      @instructions = body.strip
    end

    def parse_frontmatter(content)
      return [{}, content] unless content.start_with?('---')

      parts = content.split('---', 3)
      return [{}, content] if parts.length < 3

      frontmatter_content = parts[1]
      body = parts[2]

      begin
        require 'yaml'
        [YAML.safe_load(frontmatter_content), body]
      rescue Psych::SyntaxError
        [{}, content]
      end
    end
  end
end

module Ralph
  class Agent
    attr_reader :name, :description, :tools, :instructions

    def initialize(agent_name, client: nil)
      agent_file = File.join(File.dirname(__FILE__), "../../agents/#{agent_name}.md")
      raise "Agent file not found: #{agent_file}" unless File.exist?(agent_file)

      load_agent_config(agent_file)
      @client = client || Ralph::Client.new
    end

    def call(prompt)
      chat = @client.chat

      attach_tools(chat)
      response = chat.ask "#{@instructions}\n\n#{prompt}"
      response.content
    end

    private

    def attach_tools(chat)
      @tools.each do |tool_name|
        tool_class = Ralph::Tools.get(tool_name.to_sym)
        chat.with_tool(tool_class) if tool_class
      end
    end

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

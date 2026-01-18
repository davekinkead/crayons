module Ralph
  class Agent
    DEFAULT_MAX_ITERATIONS = 20

    attr_reader :name, :description, :tools, :instructions, :max_iterations, :id

    def initialize(agent_name, client: nil)
      agent_file = File.join(File.dirname(__FILE__), "../../agents/#{agent_name}.md")
      raise "Agent file not found: #{agent_file}" unless File.exist?(agent_file)

      load_agent_config(agent_file)
      @client = client || Ralph::Client.new
      @id = "[#{@name}:#{object_id}]"
    end

    def call(prompt)
      puts "[#{@id}] Starting agent execution"
      chat = @client.chat

      attach_tools(chat)

      iteration = 0
      @max_iterations.times do
        iteration += 1
        response = chat.ask "#{@instructions}\n\n#{prompt}"
        content = response.content.strip

        if content.include?("<promise>COMPLETE</promise>")
          puts "[#{@id}] Complete - <promise>COMPLETE</promise>"
          return "<promise>COMPLETE</promise>"
        end
      end

      puts "[#{@id}] Max iterations reached"
      final_prompt = "You've reached the maximum number of turns without completing the task. Please explain why you couldn't complete it and what went wrong."
      final_response = chat.ask final_prompt
      "<promise>FAILURE: #{final_response.content}</promise>"
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

      @max_iterations = frontmatter['max_iterations'] || DEFAULT_MAX_ITERATIONS
      validate_max_iterations!
    end

    def validate_max_iterations!
      unless @max_iterations.is_a?(Integer) && @max_iterations > 0
        raise "max_iterations must be a positive integer, got: #{@max_iterations.inspect}"
      end
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

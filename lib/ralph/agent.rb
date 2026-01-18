require_relative 'message'

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
      @messages = []
      @messages << Message.new(role: :system, content: @instructions)

      iteration = 0
      loop do
        response = chat(prompt)
        iteration += 1

        if response.tool_call?
          response.tool_calls.each { |tool_call| execute_tool(tool_call) }
          next
        end

        if response.content&.strip&.include?("<promise>COMPLETE</promise>")
          puts "[#{@id}] Complete - <promise>COMPLETE</promise>"
          return "<promise>COMPLETE</promise>"
        end

        break if iteration >= @max_iterations
      end

      puts "[#{@id}] Max iterations reached"
      final_prompt = "You've reached the maximum number of turns without completing the task. Please explain why you couldn't complete it and what went wrong."
      final_response = chat(final_prompt)
      "<promise>FAILURE: #{final_response.content}</promise>"
    end

    private

    def chat(prompt)
      @messages << Message.new(role: :user, content: prompt)
      response = @client.chat(@messages)
      @messages << response
      response
    end

    def execute_tool(tool_call)
      tool_name = tool_call['function']['name']
      tool_args = JSON.parse(tool_call['function']['arguments'])

      puts "[#{@id}] TOOL_CALL #{tool_name} #{tool_args}"

      tool_class = Ralph::Tools.get(tool_name.to_sym)
      return unless tool_class

      tool_instance = tool_class.new
      result = tool_instance.execute(**tool_args)

      puts "[#{@id}] TOOL_RESPONSE #{tool_name} #{result}"

      @messages << Message.new(
        role: :tool,
        tool_call_id: tool_call['id'],
        content: result.to_json
      )
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

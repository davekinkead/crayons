require "yaml"
require_relative "clients/openai"
require_relative "tools/bash"
require_relative "tools/files"

module Ralph
  class Agent
    attr_reader :name, :description, :tools, :config, :context, :client, :messages

    def initialize(agent_path, client:)
      @agent_path = agent_path
      @config = parse_frontmatter(agent_path)
      @name = @config["name"]
      @description = @config["description"]
      @tools = @config["tools"]
      @context = {}
      @client = client
      @messages = []
    end

    def run(max_turns: 10)
      load_system_prompt

      max_turns.times do |turn|
        response = @client.chat(messages: @messages, tools: build_tools)

        if response["tool_calls"]
          @messages << { role: "assistant", tool_calls: response["tool_calls"] }

          tool_responses = execute_tools(response["tool_calls"])
          @messages.concat(tool_responses)

          next
        end

        @messages << { role: "assistant", content: response["content"] }

        return success_result(turn) if complete?(response["content"])
      end

      max_turns_result
    end

    class << self
      def new(name, client:)
        path = find_agent_file(name)
        super(path, client:)
      end

      private

      def find_agent_file(name)
        path = File.join("agents", "#{name.upcase}.md")
        raise Ralph::Error, "Agent file not found: #{path}" unless File.exist?(path)

        path
      end
    end

    private

    def load_system_prompt
      content = File.read(@agent_path)
      match = content.match(/^---$(.*?)^---$(.*)/m)
      instructions = match[2].strip

      available_tools = @config["tools"]&.map { |t| t.upcase }&.join(", ") || "None"
      full_prompt = "#{instructions}\n\nAvailable tools: #{available_tools}"

      @messages << { role: "system", content: full_prompt }
    end

    def build_tools
      tools = []

      if @config["tools"]&.include?("bash")
        tools << {
          type: "function",
          function: {
            name: "bash",
            description: "Execute a bash command in the terminal",
            parameters: {
              type: "object",
              properties: {
                command: {
                  type: "string",
                  description: "The bash command to execute"
                }
              },
              required: ["command"]
            }
          }
        }
      end

      if @config["tools"]&.include?("files")
        tools << {
          type: "function",
          function: {
            name: "read_file",
            description: "Read the contents of a file",
            parameters: {
              type: "object",
              properties: {
                path: {
                  type: "string",
                  description: "The path to the file to read"
                }
              },
              required: ["path"]
            }
          }
        }
      end

      tools
    end

    def execute_tools(tool_calls)
      tool_calls.map do |call|
        result = case call["function"]["name"]
                 when "bash"
                   args = JSON.parse(call["function"]["arguments"])
                   Tools::Bash.run(args["command"])
                 when "read_file"
                   args = JSON.parse(call["function"]["arguments"])
                   Tools::Files.read(args["path"])
                 else
                   "Unknown tool: #{call["function"]["name"]}"
                 end

        {
          role: "tool",
          tool_call_id: call["id"],
          content: result.to_s
        }
      end
    end

    def complete?(content)
      content.include?("<promise>COMPLETE</promise>")
    end

    def success_result(turns)
      {
        status: :success,
        turns: turns + 1,
        messages: @messages
      }
    end

    def max_turns_result
      {
        status: :max_turns,
        turns: @messages.length,
        messages: @messages
      }
    end

    def parse_frontmatter(path)
      content = File.read(path)
      match = content.match(/^---$(.*?)^---$/m)
      return {} unless match

      YAML.load(match[1])
    end
  end
end

require 'yaml'
require_relative '../clients/openai'
require_relative '../tools/bash'
require_relative '../tools/files'

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

      def run(prd:, failing_tests:, max_turns: 10)
        load_system_prompt
        load_initial_task(prd, failing_tests)

        max_turns.times do |turn|
          response = @client.chat(messages: @messages)
          @messages << { role: 'assistant', content: response }

          return success_result(turn) if complete?(response)

          tool_results = execute_tools(response)
          @messages << { role: 'user', content: format_tool_results(tool_results) }
        end

        max_turns_result
      end

      private

      def load_system_prompt
        content = File.read(@agent_path)
        match = content.match(/^---$(.*?)^---$(.*)/m)
        instructions = match[2].strip

        available_tools = @config['tools']&.map { |t| t.upcase }&.join(', ') || 'None'
        full_prompt = "#{instructions}\n\nAvailable tools: #{available_tools}"

        @messages << { role: 'system', content: full_prompt }
      end

      def load_initial_task(prd, failing_tests)
        task = <<~TASK
          PRD:
          #{prd}

          Failing tests:
          #{failing_tests}

          Start by reading the relevant files to understand the codebase, then implement the solution.
        TASK

        @messages << { role: 'user', content: task }
      end

      def complete?(response)
        response.include?('<promise>COMPLETE</promise>')
      end

      def execute_tools(response)
        results = []

        response.scan(/BASH:\s*(.+)/).each do |match|
          command = match[0].strip
          results << "BASH: #{command}"
          results << Tools::Bash.run(command)
        end

        response.scan(/FILES:\s*READ\s+(.+)/).each do |match|
          path = match[0].strip
          results << "FILES: READ #{path}"
          results << Tools::Files.read(path)
        end

        response.scan(/FILES:\s*WRITE\s+(.+?)\n(.+)/).each do |match|
          path = match[0].strip
          content = match[1].strip
          results << "FILES: WRITE #{path}"
          Tools::Files.write(path, content)
        end

        results
      end

      def format_tool_results(results)
        results.map { |r| r.is_a?(Hash) ? format_result(r) : r }.join("\n")
      end

      def format_result(result)
        if result[:success]
          '✓ Success'
        else
          "✗ Failed: #{result[:stderr]}"
        end
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
          turns: @messages.length / 2,
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
end

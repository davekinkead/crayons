# frozen_string_literal: true
require "async"
require "json"

module Crayons
  class BatchTool < Tool
    description "Execute multiple tool calls concurrently. IMPORTANT: Call this tool directly as a tool, NOT through bash. When you need to run multiple tools at once, use batch instead of calling them separately. Returns results in same order as input calls. Example usage: batch calls=[{\"tool_name\":\"read\",\"arguments\":{\"file_path\":\"README.md\"}},{\"tool_name\":\"bash\",\"arguments\":{\"command\":\"ls\"}}]"

    params do
      string :calls, description: "JSON array of tool calls. Each element is an object with 'tool_name' and 'arguments' keys. For example: to read a file and run a command simultaneously, pass: [{\"tool_name\":\"read\",\"arguments\":{\"file_path\":\"README.md\"}},{\"tool_name\":\"bash\",\"arguments\":{\"command\":\"ls\"}}]"
    end

    def execute(calls:)
      parsed_calls = parse_calls_parameter(calls)
      return { success: true, results: [], errors: [] } if parsed_calls.empty?

      tool_calls = validate_and_parse_calls(parsed_calls)
      deduplicated_calls = deduplicate_calls(tool_calls)

      results = execute_concurrent_calls(deduplicated_calls)
      ordered_results = restore_order(tool_calls, results)

      all_success = ordered_results.all? { |r| r[:success] }
      errors = ordered_results.reject { |r| r[:success] }

      {
        success: all_success,
        results: ordered_results,
        errors: errors.map { |e| e.slice(:tool_name, :arguments, :error) }
      }
    end

    private

    def parse_calls_parameter(calls)
      if calls.is_a?(String)
        JSON.parse(calls)
      elsif calls.is_a?(Array)
        calls
      else
        raise "calls must be a JSON string or array"
      end
    rescue JSON::ParserError => e
      raise "Invalid JSON in calls parameter: #{e.message}"
    end

    def validate_and_parse_calls(calls)
      calls.map.with_index do |call, idx|
        raise "Call at index #{idx} must be a hash" unless call.is_a?(Hash)

        call.transform_keys(&:to_sym).tap do |parsed_call|
          parsed_call[:arguments] = symbolize_keys(parsed_call[:arguments]) if parsed_call[:arguments].is_a?(Hash)
        end
      end
    rescue StandardError => e
      raise "Invalid calls format: #{e.message}"
    end

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end

    def deduplicate_calls(calls)
      seen = {}
      calls.each_with_index do |call, idx|
        key = call_key(call)
        seen[key] ||= { call:, original_index: idx }
      end
      seen.values.map { |v| v[:call] }
    end

    def call_key(call)
      {
        tool_name: call[:tool_name],
        arguments: normalized_arguments(call[:arguments])
      }
    end

    def normalized_arguments(args)
      return {} unless args.is_a?(Hash)

      args.transform_keys(&:to_sym)
    end

    def execute_concurrent_calls(calls)
      results = []

      Sync do
        tasks = calls.map do |call|
          Async do
            execute_single_tool(call)
          end
        end

        tasks.each do |task|
          results << task.wait
        end
      end

      results
    end

    def execute_single_tool(call)
      tool_name = call[:tool_name]
      arguments = call[:arguments]

      tool_class = Crayons::Tools.get(tool_name.to_sym)
      return build_error_result(tool_name, arguments, "Tool not found: #{tool_name}") unless tool_class

      tool_instance = tool_class.new
      result = tool_instance.execute(**arguments)

      if result[:success] == false
        error = result[:error] || "Tool execution failed"
        build_error_result(tool_name, arguments, error)
      else
        build_success_result(tool_name, arguments, result)
      end
    rescue StandardError => e
      build_error_result(tool_name, arguments, e.message)
    end

    def build_success_result(tool_name, arguments, result)
      {
        tool_name:,
        arguments:,
        result:,
        success: true,
        error: nil
      }
    end

    def build_error_result(tool_name, arguments, error)
      {
        tool_name:,
        arguments:,
        result: nil,
        success: false,
        error:
      }
    end

    def restore_order(original_calls, executed_results)
      executed_results_by_key = {}
      executed_results.each do |result|
        key = call_key(result)
        executed_results_by_key[key] = result
      end

      original_calls.map do |call|
        key = call_key(call)
        executed_results_by_key[key]
      end
    end
  end
end

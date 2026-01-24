# frozen_string_literal: true

require "async"
require_relative "../tool"

module Crayons
  module Tools
    class Batch < Crayons::Tool
      def name = "batch"
      def description = "Execute multiple tools in a single call"
      def params = [{ name: "tools", description: "Array of tool calls with tool name and input", required: true }]

      def call(input)
        tools = input[:tools] || input["tools"]
        return { success: true, result: [{ success: false, result: "Error: 'tools' key is required" }] } if tools.nil?
        return { success: true, result: [{ success: false, result: "Error: 'tools' must be an Array" }] } unless tools.is_a?(Array)

        results = Array.new(tools.length)

        Async do
          tools.each_with_index do |tool_call, index|
            Async do
              tool_name = tool_call[:tool] || tool_call["tool"]
              tool_input = tool_call[:input] || tool_call["input"]
              raise "tool call missing 'tool' key" if tool_name.nil?
              raise "tool call missing 'input' key" if tool_input.nil?

              results[index] = Crayons::Tools.new(tool_name).call(tool_input)
            rescue StandardError => e
              results[index] = { success: false, result: "Error: #{tool_name} - #{e.message}" }
            end
          end
        end

        { success: true, result: results }
      end
    end
  end
end

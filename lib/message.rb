# frozen_string_literal: true

module Crayons
  class Message
    attr_reader :role, :content, :complete, :tool_calls, :tool_call_id

    def initialize(role:, content: nil, complete: false, tool_calls: nil, tool_call_id: nil)
      @role = role
      @content = content
      @complete = complete
      @tool_calls = tool_calls
      @tool_call_id = tool_call_id
    end

    def tool_call?
      !@tool_calls.nil? && !@tool_calls.empty?
    end

    def complete?
      @complete
    end
  end
end

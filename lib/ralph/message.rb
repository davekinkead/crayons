module Ralph
  class Message
    attr_reader :role, :content, :tool_calls, :tool_call_id

    def initialize(role:, content: nil, tool_calls: nil, tool_call_id: nil)
      @role = role
      @content = content
      @tool_calls = tool_calls
      @tool_call_id = tool_call_id
    end

    def tool_call?
      !@tool_calls.nil? && !@tool_calls.empty?
    end
  end
end

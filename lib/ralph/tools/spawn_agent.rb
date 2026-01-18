module Ralph
  class SpawnAgentTool < Tool
    description "Spawn and execute another agent (CODER, REVIEWER, etc.) with fresh context"

    params do
      string :agent_name, description: "Name of agent to spawn (e.g., 'CODER', 'REVIEWER')"
      string :instructions, description: "Prompt/instructions for the spawned agent"
    end

    def execute(agent_name:, instructions:)
      # Convert to string if symbol is passed
      agent_name_str = agent_name.to_s

      begin
        # Create a new agent instance with its own fresh context
        agent = Ralph::Agent.new(agent_name_str)
        
        # Call the agent with the instructions
        response = agent.call(instructions)
        
        # Return the agent's raw response (including promise tags)
        response
      rescue => e
        # Handle any errors during agent initialization or execution
        error_message = e.message
        
        # If it's an agent file not found error, include available agents
        if error_message.include?('Agent file not found')
          available_agents = list_available_agents
          error_message += "\n\nAvailable agents: #{available_agents.join(', ')}"
        end
        
        { error: error_message, success: false }
      end
    end

    private

    def list_available_agents
      agents_dir = File.join(File.dirname(__FILE__), "../../../agents")
      return [] unless Dir.exist?(agents_dir)

      Dir.glob("#{agents_dir}/*.md").map do |file|
        File.basename(file, '.md')
      end.sort
    end
  end
end

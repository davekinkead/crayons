require_relative '../clients/openai'
require_relative 'agent'

module Ralph
  class Orchestrator
    def self.run(agent_name:, prd:, test_path:)
      client = Clients::OpenAI.new
      agent = Agent.new(agent_name, client:)

      failing_tests = extract_failing_tests(test_path)

      agent.run(prd:, failing_tests:)
    end

    def self.extract_failing_tests(test_path)
      "1) #{test_path}:4 - Foo Class Method returns string \"bar\""
    end
  end
end

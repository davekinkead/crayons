# frozen_string_literal: true

require_relative "../../lib/agent"

RSpec.describe "Agent.call with real LLM" do
  it "finds files related to haikus" do
    agent = Crayons::Agent.new(:test)

    prompt = "Find file names related to haikus"
    pp prompt

    response = agent.call prompt

    pp "Message history:"
    agent.instance_variable_get(:@message_history).each { |msg| pp msg.content }

    expect(response).to be_a(Crayons::Message)
    expect(response.complete?).to be true
    expect(response.content).to be_a(String)
  end
end

# frozen_string_literal: true

require_relative "../../lib/agent"

RSpec.describe "Agent.chat with real LLM" do
  it "successfully sends messages and receives a response" do
    agent = Crayons::Agent.new(:test)

    message = Crayons::Message.new(role: :user, content: "Write a haiku")
    request = { messages: [message], tools: [] }
    pp "Request:"
    pp request

    response = agent.chat(messages: [message])
    pp "Response:"
    pp response

    expect(response).to be_a(Crayons::Message)
    expect(response.content).to be_a(String)
    expect(response.content.length).to be > 0
  end
end

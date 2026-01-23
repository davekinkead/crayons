# frozen_string_literal: true

require_relative "../../lib/clients/zai"

RSpec.describe "Zai client integration tests" do
  let(:api_key) { ENV.fetch("ZAI_API_KEY", nil) }

  before do
    skip("Set ZAI_API_KEY environment variable to run integration tests") unless api_key
  end

  it "connects to Zai API and receives a valid response" do
    client = Crayons::Clients::Zai.new(api_key: api_key)

    system = "You are a helpful assistant"
    messages = [Crayons::Message.new(role: :user, content: "Hello!")]

    request = { system:, messages:, tools: [] }
    pp "Request........"
    pp request

    result = client.chat(system: system, messages: messages, tools: [])

    pp "Response......."
    pp result

    expect(result).to be_a(Crayons::Message)
    expect(result.role).to eq(:assistant)
    expect(result.content).to be_a(String)
    expect(result.content).not_to be_empty
  end
end

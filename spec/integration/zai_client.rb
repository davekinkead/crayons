# frozen_string_literal: true

require_relative "../../lib/clients/zai"

RSpec.describe "Zai client integration tests" do
  let(:api_key) { ENV.fetch("ZAI_API_KEY") }
  let(:client) { Crayons::Clients::Zai.new(api_key: api_key) }

  before do
    skip("Set ZAI_API_KEY environment variable to run integration tests") unless api_key
  end

  it "connects to Zai API successfully" do
    expect(client).to be_a(Crayons::Clients::Zai)
    expect(client.instance_variable_get(:@api_key)).to eq(api_key)
  end

  it "sends a simple chat request" do
    system = "You are a helpful assistant"
    messages = [Crayons::Message.new(role: :user, content: "Hello!")]
    
    result = client.chat(system: system, messages: messages, tools: [])

    expect(result).to be_a(Crayons::Message)
    expect(result.role).to eq(:assistant)
    expect(result.content).to be_a(String)
    expect(result.content).not_to be_empty
  end

  it "handles multi-turn conversations" do
    system = "You are a helpful assistant"
    messages = [
      Crayons::Message.new(role: :user, content: "What is 2+2?"),
      Crayons::Message.new(role: :assistant, content: "2+2=4"),
      Crayons::Message.new(role: :user, content: "And what about 3+3?")
    ]
    
    result = client.chat(system: system, messages: messages, tools: [])

    expect(result).to be_a(Crayons::Message)
    expect(result.content).to be_a(String)
    expect(result.content).to match(/6/)
  end

  it "completes responses correctly" do
    system = "You are a helpful assistant"
    messages = [Crayons::Message.new(role: :user, content: "Say 'done'")]
    
    result = client.chat(system: system, messages: messages, tools: [])

    expect(result.complete?).to be true
  end

  it "handles errors gracefully" do
    skip("Requires invalid API key configuration")
  end
end

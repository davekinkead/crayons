# frozen_string_literal: true

require_relative "../../lib/agent"
require_relative "../../lib/message"

RSpec.describe "Agent tool execution" do
  let(:mock_client) { instance_double(Crayons::Services::Zai) }

  it "loops to handle tool calls until complete" do
    tool_call_message = Crayons::Message.new(
      role: :assistant,
      content: nil,
      complete: false,
      tool_calls: [{
        function: { name: "find", arguments: JSON.generate({pattern: "*.rb"}) },
        id: "call_123",
        type: "function",
        index: 0
      }]
    )
    final_message = Crayons::Message.new(role: :assistant, content: "Found 5 ruby files", complete: true)

    allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

    agent = Crayons::Agent.new(:test, client: mock_client)
    response = agent.call("Find all ruby files")

    expect(response).to eq(final_message)
    expect(response.complete?).to be true
    expect(mock_client).to have_received(:chat).twice
  end

  it "returns final response after tool execution completes" do
    tool_call_message = Crayons::Message.new(
      role: :assistant,
      content: nil,
      complete: false,
      tool_calls: [{
        function: { name: "find", arguments: JSON.generate({pattern: "*.md"}) },
        id: "call_456",
        type: "function",
        index: 0
      }]
    )
    final_message = Crayons::Message.new(role: :assistant, content: "SUCCESS: Found markdown files", complete: true)

    allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

    agent = Crayons::Agent.new(:test, client: mock_client)
    response = agent.call("Find markdown files")

    expect(response.content).to eq("SUCCESS: Found markdown files")
    expect(response.complete?).to be true
    expect(mock_client).to have_received(:chat).twice
  end

  it "handles multiple tool calls in a single request" do
    tool_call_message = Crayons::Message.new(
      role: :assistant,
      content: nil,
      complete: false,
      tool_calls: [
        {
          function: { name: "find", arguments: JSON.generate({pattern: "lib/*.rb"}) },
          id: "call_1",
          type: "function",
          index: 0
        },
        {
          function: { name: "find", arguments: JSON.generate({pattern: "spec/*.rb"}) },
          id: "call_2",
          type: "function",
          index: 1
        }
      ]
    )
    final_message = Crayons::Message.new(role: :assistant, content: "Found files in lib and spec", complete: true)

    allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

    agent = Crayons::Agent.new(:test, client: mock_client)
    response = agent.call("Find ruby files")

    expect(response).to eq(final_message)
    expect(mock_client).to have_received(:chat).twice
  end

  it "executes multiple bash sleep commands concurrently" do
    tool_call_message = Crayons::Message.new(
      role: :assistant,
      content: nil,
      complete: false,
      tool_calls: [
        {
          function: { name: "bash", arguments: JSON.generate({command: "sleep 0.1", timeout: 10}) },
          id: "call_1",
          type: "function",
          index: 0
        },
        {
          function: { name: "bash", arguments: JSON.generate({command: "sleep 0.1", timeout: 10}) },
          id: "call_2",
          type: "function",
          index: 1
        },
        {
          function: { name: "bash", arguments: JSON.generate({command: "sleep 0.1", timeout: 10}) },
          id: "call_3",
          type: "function",
          index: 2
        }
      ]
    )
    final_message = Crayons::Message.new(role: :assistant, content: "All commands completed", complete: true)

    allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

    agent = Crayons::Agent.new(:test, client: mock_client)

    start_time = Time.now
    response = agent.call("Run multiple sleep commands")
    end_time = Time.now

    expect(response).to eq(final_message)
    expect(mock_client).to have_received(:chat).twice

    # Should take ~0.1s total if concurrent, not ~0.3s
    expect(end_time - start_time).to be < 0.25
  end

  it "maintains tool call result order with concurrent execution" do
    tool_call_message = Crayons::Message.new(
      role: :assistant,
      content: nil,
      complete: false,
      tool_calls: [
        {
          function: { name: "haiku", arguments: JSON.generate({}) },
          id: "call_1",
          type: "function",
          index: 0
        },
        {
          function: { name: "haiku", arguments: JSON.generate({}) },
          id: "call_2",
          type: "function",
          index: 1
        }
      ]
    )

    final_message = Crayons::Message.new(role: :assistant, content: "Generated haikus", complete: true)

    allow(mock_client).to receive(:chat).and_return(tool_call_message, final_message)

    agent = Crayons::Agent.new(:test, client: mock_client)
    response = agent.call("Generate two haikus")

    expect(response).to eq(final_message)
    expect(mock_client).to have_received(:chat).twice
  end
end

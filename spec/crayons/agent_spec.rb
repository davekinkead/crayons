# frozen_string_literal: true
require "spec_helper"
require_relative "../../lib/crayons"

RSpec.describe Crayons::Agent do
  describe "#initialize" do
    it "loads agent configuration from markdown file" do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(instance_double("Crayons::Clients::Zai"))
      agent = Crayons::Agent.new("MARGE")
      expect(agent.name).to eq("MARGE")
      expect(agent.description).to eq("An expert software coding agent")
    end

    it "loads tools from agent frontmatter" do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(instance_double("Crayons::Clients::Zai"))
      agent = Crayons::Agent.new("MARGE")
      expect(agent.tools).to contain_exactly("explore", "bash", "read_file", "write_file", "edit_file", "grep", "glob")
    end

    it "loads agent instructions from markdown content" do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(instance_double("Crayons::Clients::Zai"))
      agent = Crayons::Agent.new("HAIKU")
      expect(agent.instructions).to include("You are a Haiku bot")
    end

    it "raises error for non-existent agent" do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(instance_double("Crayons::Clients::Zai"))
      expect { Crayons::Agent.new("nonexistent") }
        .to raise_error(/Agent file not found/)
    end
  end

  describe "#call" do
    let(:client) { instance_double("Crayons::Clients::Zai", chat: nil) }
    let(:agent) { Crayons::Agent.new("HAIKU", client: client) }
    let(:logger) { Crayons::Logger.instance }

    before do
      # Clear any existing singleton instance
      Crayons::Logger.remove_instance
      @original_log_level = ENV.fetch("CRAYONS_LOG_LEVEL", nil)
      ENV["CRAYONS_LOG_LEVEL"] = "DEBUG"
    end

    after do
      ENV["CRAYONS_LOG_LEVEL"] = @original_log_level
    end

    it "logs the prompt when starting agent execution at INFO level" do
      return_message = "SUCCESS: Done"
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: return_message, complete: true)
      )

      expect(logger).to receive(:info).ordered.with(
        /AGENT:#{agent.id}/,
        /Starting: Write me a haiku/
      )
      expect(logger).to receive(:info).ordered.with(
        /AGENT:#{agent.id}/,
        /Completed: #{Regexp.escape(return_message)}/
      )

      agent.call("Write me a haiku")
    end

    it "logs the return message when agent completes at INFO level" do
      return_message = "SUCCESS: Haiku written successfully"
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: return_message, complete: true)
      )

      expect(logger).to receive(:info).ordered.with(
        /AGENT:#{agent.id}/,
        /Starting: Write me a haiku/
      )
      expect(logger).to receive(:info).ordered.with(
        /AGENT:#{agent.id}/,
        /Completed: #{Regexp.escape(return_message)}/
      )

      agent.call("Write me a haiku")
    end

    it "logs both prompt and return message for successful execution" do
      return_message = "SUCCESS: Haiku written successfully"
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: return_message, complete: true)
      )

      expect(logger).to receive(:info).ordered.with(/AGENT:#{agent.id}/, /Starting:/)
      expect(logger).to receive(:info).ordered.with(/AGENT:#{agent.id}/, /Completed:/)

      agent.call("Write me a haiku")
    end

    it "preserves existing logging behavior for max iterations warning" do
      call_count = 0
      expect(client).to receive(:chat).exactly(6).times do
        call_count += 1
        Crayons::Message.new(role: :assistant, content: "Working...", complete: false)
      end

      expect(logger).to receive(:warn).with(/AGENT:#{agent.id}/, /Max iterations reached/)

      agent.call("Write me a haiku")
    end

    it "appends default system prompt to instructions" do
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: Done", complete: true)
      )
      agent.call("Write me a haiku")
      expect(agent.instructions).to include("SUCCESS:")
      expect(agent.instructions).to include("FAILURE:")
    end

    it "preserves original agent instructions" do
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: Done", complete: true)
      )
      agent.call("Write me a haiku")
      expect(agent.instructions).to include("You are a Haiku bot")
    end

    it "sends instructions to LLM and returns response content" do
      expect(client).to receive(:chat).with(
        hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array))
      ).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: All done", complete: true)
      )

      response = agent.call("Write me a haiku")
      expect(response).to eq("SUCCESS: All done")
    end

    it "returns SUCCESS when LLM emits finish_reason=stop after multiple iterations" do
      call_count = 0
      expect(client).to receive(:chat).exactly(3).times do
        call_count += 1
        if call_count < 3
          Crayons::Message.new(role: :assistant, content: "Working...", complete: false)
        else
          Crayons::Message.new(role: :assistant, content: "SUCCESS: All done", complete: true)
        end
      end

      response = agent.call("Write me a haiku")
      expect(response).to eq("SUCCESS: All done")
    end

    it "continues looping when response is not complete" do
      call_count = 0
      expect(client).to receive(:chat).exactly(4).times do
        call_count += 1
        Crayons::Message.new(role: :assistant, content: "Still working...", complete: false)
      end

      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: All done", complete: true)
      )

      response = agent.call("Write me a haiku")
      expect(response).to eq("SUCCESS: All done")
      expect(call_count).to eq(4)
    end

    it "returns FAILURE with explanation when max iterations reached without success" do
      call_count = 0
      expect(client).to receive(:chat).exactly(5).times do
        call_count += 1
        Crayons::Message.new(role: :assistant, content: "Working...", complete: false)
      end

      expect(client).to receive(:chat).once.and_return(
        Crayons::Message.new(role: :assistant, content: "Explanation: task too complex", complete: true)
      )

      response = agent.call("Write me a haiku")
      expect(response).to start_with("FAILURE: Max iterations reached")
      expect(response).to include("Explanation: task too complex")
    end

    it "returns full content when response is complete" do
      expect(client).to receive(:chat).and_return(
        Crayons::Message.new(role: :assistant, content: "SUCCESS: Done! Here is the haiku...", complete: true)
      )

      response = agent.call("Write me a haiku")
      expect(response).to eq("SUCCESS: Done! Here is the haiku...")
    end

    it "catches StandardError and returns FAILURE message with class, message and backtrace" do
      expect(client).to receive(:chat).and_raise(StandardError.new("Something went wrong"))

      response = agent.call("Write me a haiku")
      expect(response).to start_with("FAILURE: StandardError: Something went wrong")
      expect(response).to include("\n")
    end

    it "does NOT catch Exception and lets it propagate" do
      expect(client).to receive(:chat).and_raise(Exception.new("System failure"))

      expect { agent.call("Write me a haiku") }.to raise_error(Exception, "System failure")
    end
  end

  describe "#chat" do
    let(:client) { instance_double("Crayons::Clients::Zai", chat: nil) }
    let(:agent) { Crayons::Agent.new("HAIKU", client: client) }

    it "adds user message to messages when prompt is provided" do
      response = Crayons::Message.new(role: :assistant, content: "Hello")
      expect(client).to receive(:chat).and_return(response)

      agent.chat("test prompt")

      expect(agent.messages.map(&:role)).to include(:user)
    end

    it "adds response to messages" do
      response = Crayons::Message.new(role: :assistant, content: "Hello")
      expect(client).to receive(:chat).and_return(response)

      agent.chat("test prompt")

      expect(agent.messages.last).to eq(response)
    end

    it "returns the response from client" do
      response = Crayons::Message.new(role: :assistant, content: "Hello")
      expect(client).to receive(:chat).and_return(response)

      result = agent.chat("test prompt")

      expect(result).to eq(response)
    end

    it "does not add user message when prompt is nil" do
      response = Crayons::Message.new(role: :assistant, content: "Hello")
      expect(client).to receive(:chat).and_return(response)

      agent.chat(nil)

      expect(agent.messages.map(&:role)).not_to include(:user)
    end
  end

  describe "#max_iterations" do
    let(:client) { instance_double("Crayons::Clients::Zai") }

    before do
      allow(Crayons::Clients::Zai).to receive(:new).and_return(client)
    end

    it "uses default max_iterations of 10 when not specified in frontmatter" do
      agent = Crayons::Agent.new("MARGE", client: client)
      expect(agent.max_iterations).to eq(10)
    end

    it "uses custom max_iterations from agent frontmatter" do
      agent = Crayons::Agent.new("HAIKU", client: client)
      expect(agent.max_iterations).to eq(5)
    end

    it "raises error for non-positive max_iterations in frontmatter" do
      allow_any_instance_of(Crayons::Agent).to receive(:parse_frontmatter)
        .and_return([{
          "name" => "HAIKU",
          "description" => "test",
          "tools" => [],
          "max_iterations" => -1
        }, "test"])

      expect { Crayons::Agent.new("HAIKU", client: client) }
        .to raise_error(/max_iterations must be a positive integer/)
    end
  end

  describe ".deduplicate_tool_calls" do
    it "removes previous tool call and response when duplicate is detected" do
      tool_call_1 = {
        "id" => "call_1",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls"}'
        }
      }

      tool_call_2 = {
        "id" => "call_2",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls"}'
        }
      }

      messages = [
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_1]),
        Crayons::Message.new(role: :tool, tool_call_id: "call_1", content: '{"result": "file1.txt"}'),
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_2])
      ]

      result = Crayons::Agent.deduplicate_tool_calls(messages, tool_call_2)

      expect(result.length).to eq(1)
      expect(result.first.role).to eq(:assistant)
      expect(result.first.tool_calls.first["id"]).to eq("call_2")
    end

    it "keeps different tool calls with same name but different arguments" do
      tool_call_1 = {
        "id" => "call_1",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls"}'
        }
      }

      tool_call_2 = {
        "id" => "call_2",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "pwd"}'
        }
      }

      messages = [
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_1]),
        Crayons::Message.new(role: :tool, tool_call_id: "call_1", content: '{"result": "file1.txt"}'),
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_2])
      ]

      result = Crayons::Agent.deduplicate_tool_calls(messages, tool_call_2)

      expect(result.length).to eq(3)
      expect(result[0].tool_calls.first["function"]["arguments"]).to eq('{"command": "ls"}')
      expect(result[1].tool_call_id).to eq("call_1")
      expect(result[2].tool_calls.first["function"]["arguments"]).to eq('{"command": "pwd"}')
    end

    it "removes only the most recent duplicate when multiple exist" do
      tool_call_1 = {
        "id" => "call_1",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls"}'
        }
      }

      tool_call_2 = {
        "id" => "call_2",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls"}'
        }
      }

      tool_call_3 = {
        "id" => "call_3",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls"}'
        }
      }

      messages = [
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_1]),
        Crayons::Message.new(role: :tool, tool_call_id: "call_1", content: '{"result": "file1.txt"}'),
        Crayons::Message.new(role: :user, content: "Check this"),
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_2]),
        Crayons::Message.new(role: :tool, tool_call_id: "call_2", content: '{"result": "file2.txt"}'),
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_3])
      ]

      result = Crayons::Agent.deduplicate_tool_calls(messages, tool_call_3)

      expect(result.length).to eq(4)
      expect(result[0].tool_calls.first["id"]).to eq("call_1")
      expect(result[2].role).to eq(:user)
      expect(result[3].tool_calls.first["id"]).to eq("call_3")
    end

    it "keeps earlier duplicates when removing most recent" do
      tool_call_1 = {
        "id" => "call_1",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls"}'
        }
      }

      tool_call_2 = {
        "id" => "call_2",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls"}'
        }
      }

      messages = [
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_1]),
        Crayons::Message.new(role: :tool, tool_call_id: "call_1", content: '{"result": "file1.txt"}'),
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_2])
      ]

      result = Crayons::Agent.deduplicate_tool_calls(messages, tool_call_2)

      expect(result.length).to eq(1)
      expect(result.first.tool_calls.first["id"]).to eq("call_2")
    end

    it "handles complex nested arguments correctly" do
      tool_call_1 = {
        "id" => "call_1",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls", "options": {"all": true, "long": true}}'
        }
      }

      tool_call_2 = {
        "id" => "call_2",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls", "options": {"all": true, "long": true}}'
        }
      }

      messages = [
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_1]),
        Crayons::Message.new(role: :tool, tool_call_id: "call_1", content: '{"result": "files"}'),
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_2])
      ]

      result = Crayons::Agent.deduplicate_tool_calls(messages, tool_call_2)

      expect(result.length).to eq(1)
      expect(result.first.tool_calls.first["id"]).to eq("call_2")
    end

    it "keeps different nested argument structures" do
      tool_call_1 = {
        "id" => "call_1",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls", "options": {"all": true}}'
        }
      }

      tool_call_2 = {
        "id" => "call_2",
        "function" => {
          "name" => "bash",
          "arguments" => '{"command": "ls", "options": {"all": false}}'
        }
      }

      messages = [
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_1]),
        Crayons::Message.new(role: :tool, tool_call_id: "call_1", content: '{"result": "files"}'),
        Crayons::Message.new(role: :assistant, content: nil, tool_calls: [tool_call_2])
      ]

      result = Crayons::Agent.deduplicate_tool_calls(messages, tool_call_2)

      expect(result.length).to eq(3)
    end
  end

  describe "execute_tool with duplicate removal" do
    let(:client) { instance_double("Crayons::Clients::Zai") }
    let(:agent) { Crayons::Agent.new("MARGE", client: client) }
    let(:tool_instance) { instance_double("Crayons::BashTool") }

    before do
      allow(Crayons::BashTool).to receive(:new).and_return(tool_instance)
      messages_before = agent.messages.length
      agent.send(:execute_tool, tool_call_2)
      messages_after = agent.messages.length

      expect(messages_after).to eq(messages_before)
      expect(agent.messages.last.tool_call_id).to eq("call_2")
    end
  end
end

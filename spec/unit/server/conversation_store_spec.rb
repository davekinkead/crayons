# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Server::ConversationStore do
  let(:store_path) { "spec/fixtures/test_conversations.json" }
  let(:store) { described_class.new(store_path) }

  before do
    FileUtils.mkdir_p("spec/fixtures")
    FileUtils.rm_f(store_path)
  end

  after do
    FileUtils.rm_f(store_path)
  end

  describe "#initialize" do
    it "creates store with given path" do
      expect(store.path).to eq(store_path)
    end

    it "initializes empty conversations if file does not exist" do
      expect(store.all).to eq([])
    end
  end

  describe "#all" do
    it "returns empty array when file does not exist" do
      expect(store.all).to eq([])
    end

    it "returns loaded conversations from file" do
      data = {
        "conversations" => [
          {
            "id" => "123",
            "agent" => "GENERAL",
            "started_at" => "2026-02-12T12:00:00Z",
            "messages" => [
              { "role" => "user", "content" => "Hello", "timestamp" => "2026-02-12T12:00:00Z" }
            ]
          }
        ],
        "current_conversation_id" => "123"
      }
      File.write(store_path, JSON.generate(data))

      conversations = store.all

      expect(conversations.length).to eq(1)
      expect(conversations.first[:id]).to eq("123")
    end
  end

  describe "#create" do
    it "creates a new conversation with unique id" do
      conversation = store.create("GENERAL")

      expect(conversation[:id]).to be_a(String)
      expect(conversation[:agent]).to eq("GENERAL")
      expect(conversation[:messages]).to eq([])
      expect(conversation[:started_at]).to be_a(Time)
    end

    it "saves conversation to file" do
      store.create("RALPH")

      conversations = store.all

      expect(conversations.length).to eq(1)
      expect(conversations.first[:agent]).to eq("RALPH")
    end
  end

  describe "#find" do
    it "returns conversation by id" do
      created = store.create("GENERAL")

      found = store.find(created[:id])

      expect(found[:id]).to eq(created[:id])
      expect(found[:agent]).to eq("GENERAL")
    end

    it "returns nil when conversation not found" do
      result = store.find("nonexistent")

      expect(result).to be_nil
    end
  end

  describe "#add_message" do
    it "adds message to conversation" do
      conversation = store.create("GENERAL")

      store.add_message(conversation[:id], role: :user, content: "Hello")

      updated = store.find(conversation[:id])

      expect(updated[:messages].length).to eq(1)
      expect(updated[:messages].first[:role]).to eq(:user)
      expect(updated[:messages].first[:content]).to eq("Hello")
      expect(updated[:messages].first[:timestamp]).to be_a(Time)
    end

    it "returns nil when conversation not found" do
      result = store.add_message("nonexistent", role: :user, content: "Hello")

      expect(result).to be_nil
    end

    it "saves updated conversation to file" do
      conversation = store.create("GENERAL")
      store.add_message(conversation[:id], role: :user, content: "Hello")

      new_store = described_class.new(store_path)
      loaded = new_store.find(conversation[:id])

      expect(loaded[:messages].length).to eq(1)
    end
  end

  describe "#current_conversation_id" do
    it "returns nil when no current conversation" do
      expect(store.current_conversation_id).to be_nil
    end

    it "returns the current conversation id from file" do
      data = {
        "conversations" => [],
        "current_conversation_id" => "123"
      }
      File.write(store_path, JSON.generate(data))

      expect(store.current_conversation_id).to eq("123")
    end
  end

  describe "#set_current_conversation" do
    it "sets the current conversation id" do
      conversation = store.create("GENERAL")

      store.set_current_conversation(conversation[:id])

      expect(store.current_conversation_id).to eq(conversation[:id])
    end

    it "persists current conversation to file" do
      conversation = store.create("GENERAL")
      store.set_current_conversation(conversation[:id])

      new_store = described_class.new(store_path)

      expect(new_store.current_conversation_id).to eq(conversation[:id])
    end
  end
end

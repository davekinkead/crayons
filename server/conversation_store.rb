# frozen_string_literal: true

require "json"
require "securerandom"
require "fileutils"

module Server
  class ConversationStore
    attr_reader :path, :conversations, :current_conversation_id

    def initialize(path)
      FileUtils.mkdir_p(File.dirname(path))

      @path = path
      @conversations = load_conversations(path)
      @current_conversation_id = load_current_conversation_id(path)
    end

    def all
      conversations.values
    end

    def create(agent_name)
      id = SecureRandom.uuid
      conversation = {
        id: id,
        agent: agent_name,
        started_at: Time.now.to_s
      }
      conversations[id] = conversation
      append_log(:create, id:, agent: agent_name)
      set_current_conversation(id)
      conversation
    end

    def find(id)
      conversations[id]
    end

    def add_message(conversation_id, role:, content:)
      conversation = find(conversation_id)
      return nil unless conversation

      message = {
        role: role,
        content: content,
        timestamp: Time.now.to_s
      }
      conversation[:messages] ||= []
      conversation[:messages] << message
      append_log(:message, conversation_id:, role:, content:)
      message
    end

    def set_current_conversation(id)
      @current_conversation_id = id
      append_log(:set_current, id:)
    end

    private

    def load_conversations(path)
      return {} unless File.exist?(path)

      conversations = {}
      File.foreach(path) do |line|
        data = JSON.parse(line, symbolize_names: true)
        case data[:type]
        when "create"
          conversations[data[:id]] = {
            id: data[:id],
            agent: data[:agent],
            started_at: data[:started_at],
            messages: []
          }
        when "message"
          conv = conversations[data[:conversation_id]]
          conv[:messages] ||= []
          conv[:messages] << {
            role: data[:role],
            content: data[:content],
            timestamp: data[:timestamp]
          }
        end
      end
      conversations
    rescue JSON::ParserError
      {}
    end

    def load_current_conversation_id(path)
      return nil unless File.exist?(path)

      current_id = nil
      File.foreach(path) do |line|
        data = JSON.parse(line, symbolize_names: true)
        current_id = data[:id] if data[:type] == "set_current"
      end
      current_id
    rescue JSON::ParserError
      nil
    end

    def append_log(type, **data)
      entry = { type:, **data }
      File.open(path, "a") do |f|
        f.puts(JSON.generate(entry))
      end
    end
  end
end

# frozen_string_literal: true

require "json"
require "securerandom"
require "fileutils"

module Server
  class ConversationStore
    attr_reader :path

    def initialize(path)
      @path = path
      @data = load_data
    end

    def all
      @data[:conversations] || []
    end

    def create(agent_name)
      id = SecureRandom.uuid
      conversation = {
        id: id,
        agent: agent_name,
        started_at: Time.now,
        messages: []
      }
      @data[:conversations] << conversation
      save_data
      conversation
    end

    def find(id)
      @data[:conversations].find { |c| c[:id] == id }
    end

    def add_message(conversation_id, role:, content:)
      conversation = find(conversation_id)
      return nil unless conversation

      message = {
        role: role,
        content: content,
        timestamp: Time.now
      }
      conversation[:messages] << message
      save_data
      message
    end

    def current_conversation_id
      @data[:current_conversation_id]
    end

    def set_current_conversation(id)
      @data[:current_conversation_id] = id
      save_data
    end

    private

    def load_data
      return default_data unless File.exist?(@path)

      JSON.parse(File.read(@path), symbolize_names: true)
    rescue JSON::ParserError
      default_data
    end

    def save_data
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(@data))
    end

    def default_data
      {
        conversations: [],
        current_conversation_id: nil
      }
    end
  end
end

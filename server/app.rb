# frozen_string_literal: true

require "sinatra"
require "json"
require_relative "../lib/agent"
require_relative "port_finder"
require_relative "conversation_store"

class CrayonsServer < Sinatra::Base
  set :port, Server::PortFinder.find_available_port
  set :server, :puma

  def store
    @store ||= Server::ConversationStore.new("data/conversations.json")
  end

  get "/" do
    send_file File.expand_path("../clients/web/index.html", __dir__)
  end

  get "/conversations" do
    content_type :json
    conversation_id = store.current_conversation_id
    return {}.to_json unless conversation_id

    conversation = store.find(conversation_id)
    return {}.to_json unless conversation

    { messages: conversation[:messages] }.to_json
  end

  post "/message" do
    content = request.body.read
    data = JSON.parse(content)
    message = data["message"]
    return { error: "Message required" }.to_json unless message

    conversation_id = ensure_conversation

    store.add_message(conversation_id, role: :user, content: message)

    agent = Crayons::Agent.new(:general)
    response = agent.call(message)

    store.add_message(conversation_id, role: :assistant, content: response.content || "")

    content_type :json
    { response: response.content }.to_json
  end

  private

  def ensure_conversation
    id = store.current_conversation_id
    return id if id

    conversation = store.create("GENERAL")
    store.set_current_conversation(conversation[:id])
    conversation[:id]
  end
end

# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons"

RSpec.describe Crayons::ExploreTool do
  let(:tool) { Crayons::ExploreTool.new }

  describe "#execute" do
    context "with valid problem description" do
      let(:client_instance) { instance_double(Crayons::Clients::Zai, chat: nil) }

      before do
        allow(Crayons::Clients::Zai).to receive(:new).and_return(client_instance)
      end

      it "returns SUCCESS when WILLIE finds relevant files" do
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Crayons::Message.new(role: :assistant, content: "Searching...", complete: false))
          .and_return(Crayons::Message.new(role: :assistant, content: "SUCCESS: Found relevant files:\n\n[lib/auth.rb] - Handles user authentication\n[spec/auth_spec.rb] - Tests for auth module", complete: true))

        result = tool.execute(problem: "Find authentication code")

        expect(result).to start_with("SUCCESS:")
      end

      it "returns FAILURE when WILLIE fails to find relevant files" do
        allow(client_instance).to receive(:chat)
          .with(hash_including(system: be_a(String), messages: be_an(Array), tools: be_an(Array)))
          .and_return(Crayons::Message.new(role: :assistant, content: "Searching...", complete: false))
          .and_return(Crayons::Message.new(role: :assistant, content: "No results", complete: false))
          .and_return(Crayons::Message.new(role: :assistant, content: "Can't find anything", complete: false))

        result = tool.execute(problem: "Find non-existent feature")

        expect(result).to start_with("FAILURE:")
      end
    end

    context "with empty problem description" do
      it "returns error" do
        result = tool.execute(problem: "")

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).to include("Problem description cannot be empty")
      end
    end

    context "error handling" do
      it "handles WILLIE initialization failure" do
        allow(File).to receive(:exist?).and_return(false)

        result = tool.execute(problem: "Find auth code")

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).to include("not found")
      end

      it "handles execution errors gracefully" do
        allow_any_instance_of(Crayons::Agent).to receive(:call).and_raise(StandardError, "Network error")

        result = tool.execute(problem: "Find auth code")

        expect(result).to be_a(Hash)
        expect(result[:error]).not_to be_nil
        expect(result[:error]).to include("Network error")
      end
    end
  end
end

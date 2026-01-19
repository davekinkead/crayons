# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/ralph/clients/http"

RSpec.describe Ralph::Clients::HTTP do
  describe "#initialize" do
    it "stores API key" do
      client = described_class.new(api_key: "test-key", base_url: "https://test.com")
      expect(client.instance_variable_get(:@api_key)).to eq("test-key")
    end

    it "stores base URL" do
      client = described_class.new(api_key: "test-key", base_url: "https://test.com")
      expect(client.instance_variable_get(:@base_url)).to eq("https://test.com")
    end
  end

  describe "#post" do
    let(:api_key) { "test-api-key" }
    let(:base_url) { "https://api.test.com/v1" }
    let(:endpoint) { "#{base_url}/chat/completions" }
    let(:client) { described_class.new(api_key:, base_url:) }
    let(:payload) { { model: "test-model", messages: [] } }

    context "successful request" do
      it "returns parsed JSON response" do
        response_body = { "choices" => [{ "message" => { "content" => "test response" } }] }
        mock_response = double("response", status: 200, body: response_body.to_json)

        allow(HTTPX).to receive(:post).and_return(mock_response)

        result = client.post(endpoint, payload)
        expect(result).to eq(response_body)
      end

      it "sets Bearer authentication header" do
        mock_response = double("response", status: 200, body: "{}")

        expect(HTTPX).to receive(:post).with(
          endpoint,
          hash_including(
            headers: { Authorization: "Bearer #{api_key}", "Content-Type": "application/json" }
          )
        ).and_return(mock_response)

        client.post(endpoint, payload)
      end

      it "sets JSON content-type header" do
        mock_response = double("response", status: 200, body: "{}")

        expect(HTTPX).to receive(:post).with(
          endpoint,
          hash_including(
            headers: { Authorization: "Bearer #{api_key}", "Content-Type": "application/json" }
          )
        ).and_return(mock_response)

        client.post(endpoint, payload)
      end
    end
  end
end

# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons/clients/http"

RSpec.describe Crayons::Clients::HTTP do
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

    context "error responses" do
      it "raises APIError when response status is 400 or higher" do
        mock_response = double("response", status: 400, body: "Bad Request")
        allow(HTTPX).to receive(:post).and_return(mock_response)

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::APIError, /API error \(400\)/)
      end

      it "raises ResponseError when JSON parsing fails" do
        mock_response = double("response", status: 200, body: "invalid json")
        allow(HTTPX).to receive(:post).and_return(mock_response)

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::ResponseError, /Invalid JSON response/)
      end
    end

    context "HTTPX ErrorResponse handling" do
      it "raises NetworkError when response object is missing required methods" do
        # Simulate any object that doesn't respond to :status
        invalid_object = Object.new

        allow(HTTPX).to receive(:post).and_return(invalid_object)

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::NetworkError, /Network error/)
      end
    end

    context "network errors" do
      it "raises NetworkError for HTTPX::TimeoutError" do
        allow(HTTPX).to receive(:post).and_raise(HTTPX::TimeoutError.new(60, "Request timed out"))

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::NetworkError, /Network error/)
      end

      it "raises NetworkError for HTTPX::ConnectionError" do
        allow(HTTPX).to receive(:post).and_raise(HTTPX::ConnectionError.new("Connection failed"))

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::NetworkError, /Network error/)
      end

      it "raises NetworkError for Errno::ECONNREFUSED" do
        allow(HTTPX).to receive(:post).and_raise(Errno::ECONNREFUSED, "Connection refused")

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::NetworkError, /Network error/)
      end
    end
  end
end

# frozen_string_literal: true
require "spec_helper"
require_relative "../../../lib/crayons/clients/http"

RSpec.describe Crayons::Clients::HTTP do
  let(:api_key) { "test-api-key" }
  let(:base_url) { "https://api.test.com/v1" }
  let(:endpoint) { "#{base_url}/chat/completions" }
  let(:http_client) { double("http_client") }
  let(:payload) { { model: "test-model", messages: [] } }
  let(:client) { described_class.new(api_key:, base_url:, http_client:) }

  describe "#initialize" do
    context "validates configuration through behaviour" do
      it "uses stored API key when making requests" do
        mock_response = double("response", status: 200)
        allow(mock_response).to receive(:read).and_return('{"result":"ok"}')
        allow(mock_response).to receive(:close)
        expect(http_client).to receive(:post).with(
          "https://test.com/endpoint",
          satisfy { |headers| headers.is_a?(Array) && headers.any? { |h| h == ["authorization", "Bearer test-key"] } },
          anything
        ).and_return(mock_response)

        client = described_class.new(api_key: "test-key", base_url: "https://test.com", http_client:)
        client.post("https://test.com/endpoint", payload)
      end

      it "uses stored base URL when making requests" do
        mock_response = double("response", status: 200)
        allow(mock_response).to receive(:read).and_return('{"result":"ok"}')
        allow(mock_response).to receive(:close)
        expect(http_client).to receive(:post).with(
          "https://example.com/api/endpoint",
          anything,
          anything
        ).and_return(mock_response)

        client = described_class.new(api_key: api_key, base_url: "https://example.com/api", http_client:)
        client.post("https://example.com/api/endpoint", payload)
      end
    end
  end

  describe "#post" do
    context "successful request" do
      it "returns parsed JSON response" do
        response_body = { "choices" => [{ "message" => { "content" => "test response" } }] }
        mock_response = double("response", status: 200)
        allow(mock_response).to receive(:read).and_return(response_body.to_json)
        allow(mock_response).to receive(:close)

        allow(http_client).to receive(:post).and_return(mock_response)

        result = client.post(endpoint, payload)
        expect(result).to eq(response_body)
      end

      it "sets Bearer authentication header" do
        mock_response = double("response", status: 200)
        allow(mock_response).to receive(:read).and_return("{}")
        allow(mock_response).to receive(:close)

        expect(http_client).to receive(:post).with(
          endpoint,
          satisfy { |headers| headers.is_a?(Array) && headers.any? { |h| h == ["authorization", "Bearer #{api_key}"] } },
          anything
        ).and_return(mock_response)

        client.post(endpoint, payload)
      end

      it "sets JSON content-type header" do
        mock_response = double("response", status: 200)
        allow(mock_response).to receive(:read).and_return("{}")
        allow(mock_response).to receive(:close)

        expect(http_client).to receive(:post).with(
          endpoint,
          satisfy { |headers| headers.is_a?(Array) && headers.any? { |h| h == ["content-type", "application/json"] } },
          anything
        ).and_return(mock_response)

        client.post(endpoint, payload)
      end

      it "sets User-Agent header with version" do
        mock_response = double("response", status: 200)
        allow(mock_response).to receive(:read).and_return("{}")
        allow(mock_response).to receive(:close)

        expect(http_client).to receive(:post).with(
          endpoint,
          satisfy { |headers| headers.is_a?(Array) && headers.any? { |h| h == ["user-agent", "opencode/#{Crayons::VERSION}"] } },
          anything
        ).and_return(mock_response)

        client.post(endpoint, payload)
      end
    end

    context "API error responses" do
      it "raises ClientError when response status is 400 or higher and does not write to stderr" do
        mock_response = double("response", status: 400)
        allow(mock_response).to receive(:read).and_return("Bad Request")
        allow(mock_response).to receive(:close)
        allow(http_client).to receive(:post).and_return(mock_response)

        expect do
          expect { client.post(endpoint, payload) }.to raise_error(Crayons::Clients::HTTP::ClientError, /API error \(400\)/)
        end.to_not output.to_stderr
      end

      it "raises ClientError with status code in message for 500" do
        mock_response = double("response", status: 500)
        allow(mock_response).to receive(:read).and_return("Internal Server Error")
        allow(mock_response).to receive(:close)
        allow(http_client).to receive(:post).and_return(mock_response)

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::ClientError, /API error \(500\)/)
      end
    end

    context "response parsing errors" do
      it "raises ClientError when response body is not valid JSON and does not write to stderr" do
        mock_response = double("response", status: 200)
        allow(mock_response).to receive(:read).and_return("not valid json")
        allow(mock_response).to receive(:close)
        allow(http_client).to receive(:post).and_return(mock_response)

        expect do
          expect { client.post(endpoint, payload) }.to raise_error(Crayons::Clients::HTTP::ClientError, /Invalid JSON response/)
        end.to_not output.to_stderr
      end

      it "raises ClientError when response body is empty" do
        mock_response = double("response", status: 200)
        allow(mock_response).to receive(:read).and_return("")
        allow(mock_response).to receive(:close)
        allow(http_client).to receive(:post).and_return(mock_response)

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::ClientError, /Invalid JSON response/)
      end
    end

    context "network errors" do
      it "raises ClientError for client errors and does not write to stderr" do
        allow(http_client).to receive(:post).and_raise(StandardError.new("Connection failed"))

        expect do
          expect { client.post(endpoint, payload) }.to raise_error(Crayons::Clients::HTTP::ClientError, /Connection failed/)
        end.to_not output.to_stderr
      end

      it "raises ClientError for timeout errors" do
        allow(http_client).to receive(:post).and_raise(Timeout::Error.new("Request timed out"))

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::ClientError, /Request timed out/)
      end

      it "raises ClientError for connection refused errors" do
        allow(http_client).to receive(:post).and_raise(Errno::ECONNREFUSED, "Connection refused")

        expect do
          client.post(endpoint, payload)
        end.to raise_error(Crayons::Clients::HTTP::ClientError, /Connection refused/)
      end
    end
  end
end

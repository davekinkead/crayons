# frozen_string_literal: true

require "logger"
require "async/http"
require_relative "../../../lib/clients/http"
require_relative "../../../lib/logger"

RSpec.describe Crayons::Clients::HTTP do
  let(:api_key) { "test-api-key" }
  let(:base_url) { "https://api.example.com" }
  let(:url) { "#{base_url}/v1/test" }
  let(:payload) { { model: "test-model", messages: [{ role: "user", content: "test" }] } }
  
  let(:mock_response) do
    double("response", 
           status: 200,
           read: '{"result":"success"}')
  end
  
  let(:mock_http_client) do
    instance_double(Async::HTTP::Internet)
  end

  subject { described_class.new(api_key: api_key, base_url: base_url, http_client: mock_http_client) }

  describe "#initialize" do
    it "stores the api_key" do
      expect(subject.instance_variable_get(:@api_key)).to eq(api_key)
    end

    it "stores the base_url" do
      expect(subject.instance_variable_get(:@base_url)).to eq(base_url)
    end

    it "stores the http_client" do
      expect(subject.instance_variable_get(:@http_client)).to eq(mock_http_client)
    end
  end

  describe "#post" do
    before do
      allow(mock_http_client).to receive(:post).and_return(mock_response)
      allow(mock_response).to receive(:close)
    end

    it "sends POST request with correct headers" do
      expected_headers = [
        ["authorization", "Bearer #{api_key}"],
        ["content-type", "application/json"],
        ["user-agent", "opencode/#{Crayons::VERSION}"]
      ]

      expect(mock_http_client).to receive(:post)
        .with(url, expected_headers, payload.to_json)
        .and_return(mock_response)

      subject.post(url, payload)
    end

    it "parses and returns JSON response" do
      result = subject.post(url, payload)
      expect(result).to eq({ "result" => "success" })
    end

    it "closes the response after handling" do
      expect(mock_response).to receive(:close)
      subject.post(url, payload)
    end

    context "when response status is 4xx" do
      let(:mock_response) do
        double("response",
               status: 401,
               read: '{"error":"unauthorized"}')
      end

      it "raises ClientError with status code and body" do
        expect { subject.post(url, payload) }.to raise_error(
          described_class::ClientError,
          /API error \(401\)/
        )
      end
    end

    context "when response status is 5xx" do
      let(:mock_response) do
        double("response",
               status: 500,
               read: '{"error":"internal server error"}')
      end

      it "raises ClientError with status code" do
        expect { subject.post(url, payload) }.to raise_error(
          described_class::ClientError,
          /API error \(500\)/
        )
      end
    end

    context "when request times out" do
      before do
        allow(mock_http_client).to receive(:post).and_raise(Async::TimeoutError, "Request timed out")
      end

      it "raises ClientError with timeout message" do
        expect { subject.post(url, payload) }.to raise_error(
          described_class::ClientError,
          /Request timeout/
        )
      end
    end

    context "when connection is refused" do
      before do
        allow(mock_http_client).to receive(:post).and_raise(Errno::ECONNREFUSED, "Connection refused")
      end

      it "raises ClientError with connection refused message" do
        expect { subject.post(url, payload) }.to raise_error(
          described_class::ClientError,
          /Connection refused/
        )
      end
    end

    context "when response is invalid JSON" do
      let(:mock_response) do
        double("response",
               status: 200,
               read: "not valid json")
      end

      it "raises ClientError with JSON parse error message" do
        expect { subject.post(url, payload) }.to raise_error(
          described_class::ClientError,
          /Invalid JSON response/
        )
      end
    end
  end
end

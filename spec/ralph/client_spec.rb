require 'spec_helper'
require_relative '../../lib/ralph'

RSpec.describe Ralph::Client do
  after do
    ENV['ZAI_API_KEY'] = nil
    ENV['OPENAI_BASE_URL'] = nil
    ENV['OPENAI_MODEL'] = nil
  end

  describe '#initialize' do
    it 'creates a RubyLLM context with ZAI configuration' do
      ENV['ZAI_API_KEY'] = 'test-key'
      ENV['OPENAI_BASE_URL'] = 'https://api.test.com'
      ENV['OPENAI_MODEL'] = nil

      client = Ralph::Client.new
      expect(client.instance_variable_get(:@context)).to be_a(RubyLLM::Context)
    end
  end

  describe '#chat' do
    it 'returns a RubyLLM chat instance' do
      ENV['ZAI_API_KEY'] = 'test-key'
      client = Ralph::Client.new
      expect(client.chat).to be_a(RubyLLM::Chat)
    end
  end
end

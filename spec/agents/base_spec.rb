require 'tmpdir'
require_relative '../../lib/ralph'

RSpec.describe Ralph::Agents::Base do
  describe '#execute_tools' do
    let(:agent) { described_class.new('agents/CODER.md', client: double) }

    it 'parses and executes BASH command' do
      response = "I'll run the tests.\n\nBASH: echo 'test'"

      results = agent.send(:execute_tools, response)

      expect(results.first).to eq("BASH: echo 'test'")
      expect(results[1][:success]).to be true
    end

    it 'parses and executes FILES READ' do
      response = "Let me read the file.\n\nFILES: READ lib/ralph.rb"

      results = agent.send(:execute_tools, response)

      expect(results.first).to eq('FILES: READ lib/ralph.rb')
      expect(results[1]).to include("require_relative 'ralph/agent'")
    end

    it 'parses multiple tool calls' do
      response = <<~RESPONSE
        BASH: echo 'hello'
        FILES: READ lib/ralph.rb
      RESPONSE

      results = agent.send(:execute_tools, response)

      expect(results[0]).to include('BASH: echo')
      expect(results[2]).to include('FILES: READ')
    end

    it 'detects completion' do
      response = "I'm done. <promise>COMPLETE</promise>"

      expect(agent.send(:complete?, response)).to be true
    end

    it 'does not detect incomplete work' do
      response = 'Still working on it...'

      expect(agent.send(:complete?, response)).to be false
    end
  end
end

require 'tmpdir'
require_relative '../lib/ralph'

RSpec.describe Ralph::Agent do
  describe '.new' do
    it 'instantiates agent with config from markdown file' do
      client = double('client')
      agent = described_class.new('coder', client: client)

      expect(agent.name).to eq('CODER')
      expect(agent.description).to eq('An agent for writing or editing code')
      expect(agent.tools).to eq(["bash", "files"])
    end
  end

  describe "#run" do
  end
end

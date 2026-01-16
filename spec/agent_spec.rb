require_relative '../lib/ralph'

RSpec.describe Ralph::Agent do
  describe '.new' do
    it 'instantiates an agent by name' do
      client = double('client')
      agent = described_class.new('coder', client:)

      expect(agent.name).to eq('CODER')
      expect(agent.config['description']).to eq('An agent for writing or editing code')
      expect(agent.config['tools']).to eq(%w[bash files])
    end
  end
end

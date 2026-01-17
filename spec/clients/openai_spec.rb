require_relative '../../lib/ralph'
require_relative '../../lib/ralph/clients/openai'

RSpec.describe Ralph::Clients::OpenAI do
  describe '.tools' do
    it 'returns tool schemas for available tools' do
      schemas = Ralph::Clients::OpenAI.tools(%w[haiku bash])

      expect(schemas).to be_an(Array)
      expect(schemas.size).to eq(2)
    end

    it 'returns correct schema for haiku tool' do
      schemas = Ralph::Clients::OpenAI.tools(['haiku'])
      haiku_schema = schemas.first

      expect(haiku_schema[:type]).to eq('function')
      expect(haiku_schema[:function][:name]).to eq('haiku')
      expect(haiku_schema[:function][:description]).to eq('Generate a haiku poem')
      expect(haiku_schema[:function][:parameters][:type]).to eq('object')
      expect(haiku_schema[:function][:parameters][:properties][:intensity][:type]).to eq('number')
      expect(haiku_schema[:function][:parameters][:required]).to include('intensity')
    end

    it 'returns correct schema for bash tool' do
      schemas = Ralph::Clients::OpenAI.tools(['bash'])
      bash_schema = schemas.first

      expect(bash_schema[:type]).to eq('function')
      expect(bash_schema[:function][:name]).to eq('bash')
      expect(bash_schema[:function][:description]).to eq('Execute a bash command in the terminal')
      expect(bash_schema[:function][:parameters][:properties][:command][:type]).to eq('string')
      expect(bash_schema[:function][:parameters][:required]).to include('command')
    end

    it 'skips unknown tools' do
      schemas = Ralph::Clients::OpenAI.tools(%w[haiku nonexistent])

      expect(schemas.size).to eq(1)
      expect(schemas.first[:function][:name]).to eq('haiku')
    end

    it 'returns empty array for no tools' do
      schemas = Ralph::Clients::OpenAI.tools([])

      expect(schemas).to eq([])
    end
  end
end

require 'tmpdir'
require_relative '../../lib/ralph/tools/read_file'

RSpec.describe Ralph::Tools::ReadFile do
  describe '.schema' do
    it 'returns correct tool schema' do
      schema = described_class.schema

      expect(schema[:type]).to eq('function')
      expect(schema[:function][:name]).to eq('read_file')
      expect(schema[:function][:description]).to eq('Read the contents of a file')
      expect(schema[:function][:parameters][:properties][:path][:type]).to eq('string')
      expect(schema[:function][:parameters][:required]).to include('path')
    end
  end

  describe '.read' do
    it 'reads a file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'content')

        expect(described_class.read(path)).to eq('content')
      end
    end
  end
end

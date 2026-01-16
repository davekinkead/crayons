require 'tmpdir'
require_relative '../../lib/ralph'

RSpec.describe Ralph::Tools::Files do
  describe '.read' do
    it 'reads a file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'content')

        expect(described_class.read(path)).to eq('content')
      end
    end
  end

  describe '.write' do
    it 'writes a file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        described_class.write(path, 'new content')

        expect(File.read(path)).to eq('new content')
      end
    end
  end

  describe '.edit' do
    it 'replaces old_string with new_string' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'hello world')

        described_class.edit(path, 'hello', 'hi')

        expect(File.read(path)).to eq('hi world')
      end
    end

    it 'raises when old_string not found' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'hello world')

        expect do
          described_class.edit(path, 'goodbye', 'hi')
        end.to raise_error('old_string not found in file')
      end
    end

    it 'raises when old_string appears multiple times' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'hello hello world')

        expect do
          described_class.edit(path, 'hello', 'hi')
        end.to raise_error(/old_string found multiple times/)
      end
    end

    it 'replaces all occurrences with replace_all: true' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'hello hello world')

        described_class.edit(path, 'hello', 'hi', replace_all: true)

        expect(File.read(path)).to eq('hi hi world')
      end
    end
  end
end

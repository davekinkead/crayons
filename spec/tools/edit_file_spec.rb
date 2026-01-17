require 'tmpdir'
require_relative '../../lib/ralph'

RSpec.describe Ralph::Tools::EditFile do
  let(:subject) { described_class.new }

  it 'correctly defines itself' do
    expect(subject.name).to eq('EditFile')
    expect(subject.description).to eq 'Edit a file by replacing text'
    expect(subject.params[:path]).to include({
      description: 'The path to the file to edit',
      type: 'string'
    })

    expect(subject.params[:old_string]).to include({
      description: 'The text to replace',
      type: 'string'
    })

    expect(subject.params[:new_string]).to include({
      description: 'The replacement text',
      type: 'string'
    })

    expect(subject.params[:replace_all]).to include({
      description: 'Replace all occurrences',
      type: 'boolean'
    })
  end

  describe '.call' do
    it 'replaces a single occurrence' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'Hello World.')

        subject.call(
          path:,
          old_string: 'Hello',
          new_string: 'Hi'
        )

        expect(File.read(path)).to eq('Hi World.')
      end
    end

    it 'replaces all occurrences when replace_all is true' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'Hello World. Hello Universe.')

        subject.call(
          path:,
          old_string: 'Hello',
          new_string: 'Hi',
          replace_all: true
        )

        expect(File.read(path)).to eq('Hi World. Hi Universe.')
      end
    end

    it 'raises error when old_string not found' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'Hello World.')

        expect do
          subject.call(
            path:,
            old_string: 'Goodbye',
            new_string: 'Farewell'
          )
        end.to raise_error('old_string not found in file')
      end
    end

    it 'raises error when old_string found multiple times without replace_all' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'Hello World. Hello Universe.')

        expect do
          subject.call(
            path:,
            old_string: 'Hello',
            new_string: 'Hi'
          )
        end.to raise_error('old_string found multiple times, use replace_all: true or provide more context')
      end
    end
  end
end

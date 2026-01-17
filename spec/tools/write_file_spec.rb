require 'tmpdir'
require_relative '../../lib/ralph'

RSpec.describe Ralph::Tools::WriteFile do
  let(:subject) { described_class.new }

  it 'correctly defines itself' do
    expect(subject.name).to eq 'WriteFile'
    expect(subject.description).to eq 'Write content to a file'
    expect(subject.params[:path]).to include({
      description: 'The path to the file to write',
      type: 'string'
    })
    expect(subject.params[:content]).to include({
      description: 'The content to write to the file',
      type: 'string'
    })
  end

  describe '.call' do
    it 'writes content to a file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        content = 'Hello, World!'

        subject.call(path:, content:)

        expect(File.read(path)).to eq(content)
      end
    end
  end
end

require 'spec_helper'
require_relative '../../../lib/ralph'

RSpec.describe Ralph::BashTool do
  let(:tool) { Ralph::BashTool.new }

  it 'executes bash command and returns output' do
    result = tool.execute(command: 'echo "hello world"')
    expect(result[:output]).to include('hello world')
    expect(result[:exit_status]).to eq(0)
  end

  it 'handles command errors gracefully' do
    result = tool.execute(command: 'exit 1')
    expect(result[:exit_status]).to eq(1)
  end
end

RSpec.describe Ralph::ReadFileTool do
  let(:tool) { Ralph::ReadFileTool.new }

  it 'reads file contents' do
    result = tool.execute(file_path: File.expand_path('../../../Gemfile', __dir__))
    expect(result[:content]).to include('rspec')
  end

  it 'returns error for non-existent file' do
    result = tool.execute(file_path: '/nonexistent/file.txt')
    expect(result[:error]).to match(/File not found/)
  end
end

RSpec.describe Ralph::WriteFileTool do
  let(:tool) { Ralph::WriteFileTool.new }
  let(:temp_file) { "/tmp/test_#{Time.now.to_i}.txt" }

  after do
    File.delete(temp_file) if File.exist?(temp_file)
  end

  it 'writes content to file' do
    result = tool.execute(file_path: temp_file, content: 'test content')
    expect(result[:success]).to be true
    expect(result[:bytes_written]).to eq(12)
    expect(File.read(temp_file)).to eq('test content')
  end
end

RSpec.describe Ralph::EditFileTool do
  let(:tool) { Ralph::EditFileTool.new }
  let(:temp_file) { "/tmp/test_edit_#{Time.now.to_i}.txt" }

  before do
    File.write(temp_file, "Hello World\nGoodbye\n")
  end

  after do
    File.delete(temp_file) if File.exist?(temp_file)
  end

  it 'replaces single occurrence' do
    result = tool.execute(file_path: temp_file, old_string: 'World', new_string: 'Universe')
    expect(result[:success]).to be true
    expect(File.read(temp_file)).to eq("Hello Universe\nGoodbye\n")
  end

  it 'returns error for non-existent file' do
    result = tool.execute(file_path: '/nonexistent/file.txt', old_string: 'test', new_string: 'new')
    expect(result[:error]).to match(/File not found/)
  end

  it 'returns error for string not found' do
    result = tool.execute(file_path: temp_file, old_string: 'NotFound', new_string: 'new')
    expect(result[:error]).to eq('String not found in file')
  end

  it 'returns error for multiple occurrences' do
    File.write(temp_file, "Hello World\nGoodbye World\n")
    result = tool.execute(file_path: temp_file, old_string: 'World', new_string: 'Universe')
    expect(result[:error]).to eq('String found multiple times - use replace_all parameter')
  end
end

RSpec.describe Ralph::HaikuTool do
  let(:tool) { Ralph::HaikuTool.new }

  it 'generates haiku on topic' do
    result = tool.execute(topic: 'programming')
    expect(result).to be_a(String)
    expect(result.lines.count).to be <= 3
  end
end

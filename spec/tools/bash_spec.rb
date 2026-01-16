require_relative '../../lib/ralph'

RSpec.describe Ralph::Tools::Bash do
  describe '.run' do
    it 'runs a successful command' do
      result = described_class.run('echo "hello"')

      expect(result[:success]).to be true
      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to eq("hello\n")
      expect(result[:stderr]).to eq('')
    end

    it 'runs a failing command' do
      result = described_class.run('ls /nonexistent')

      expect(result[:success]).to be false
      expect(result[:exit_code]).to_not eq(0)
    end

    it 'blocks dangerous rm commands' do
      result = described_class.run('rm -rf /tmp/test')

      expect(result[:success]).to be false
      expect(result[:stderr]).to include('Dangerous command blocked')
    end

    it 'blocks destructive file writes' do
      result = described_class.run(':> /tmp/test')

      expect(result[:success]).to be false
      expect(result[:stderr]).to include('Dangerous command blocked')
    end
  end
end

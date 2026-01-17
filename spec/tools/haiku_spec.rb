require_relative '../../lib/ralph'

RSpec.describe Ralph::Tools::Haiku do
  let(:subject) { described_class.new }

  it 'correctly defines itself' do
    expect(subject.name).to eq 'Haiku'
    expect(subject.description).to eq 'Generate a haiku poem'
    expect(subject.params[:intensity]).to include({
      description: 'Intensity level of the haiku from 0.0 to 1.0',
      type: 'number',
      required: true
    })
  end

  describe '.call' do
    it 'returns a haiku' do
      expect(subject.call).to eq <<~TEXT
        Seventeen slices,
        Fill the bottom of the bowl,
        Haiku word salad.
      TEXT
    end
  end
end

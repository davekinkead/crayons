require_relative '../lib/ralph'

RSpec.describe 'Z.ai Integration' do
  it 'connects and responds to a message' do
    client = Ralph::Clients::OpenAI.new
    response = client.chat(messages: [
      { role: 'user', content: 'What is 2 + 2? Answer with just the number.' }
    ])

    expect(response).to eq('4')
  end
end

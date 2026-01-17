require 'dotenv/load'
require_relative '../../lib/ralph'
require_relative '../../lib/ralph/tools/haiku'

RSpec.describe 'Z.ai Integration' do
  it 'connects and responds to a message' do
    client = Ralph::Clients::OpenAI.new

    response = client.chat(messages: [
                             { role: 'user', content: 'What is 2 + 2? Answer with just the number.' }
                           ])

    pp '----- RESPONSE -------'
    pp response
    pp '----------------------'

    expect(response.content).to eq('4')
  end

  it 'invokes the haiku tool' do
    client = Ralph::Clients::OpenAI.new

    response = client.chat(
      messages: [
        { role: 'user', content: 'Write me a haiku with intensity 0.7.' }
      ],
      tools: [
        {
          type: 'function',
          function: {
            name: 'haiku',
            description: 'Generate a haiku poem',
            parameters: {
              type: 'object',
              properties: {
                intensity: {
                  type: 'number',
                  minimum: 0.0,
                  maximum: 1.0,
                  description: 'Intensity level of the haiku'
                }
              },
              required: ['intensity']
            }
          }
        }
      ]
    )

    pp '----- RESPONSE -------'
    pp response
    pp '----------------------'

    expect(response.tool_calls).not_to be_empty

    tool_call = response.tool_calls.first
    haiku = Ralph::Tools::Haiku.new.call

    final_response = client.chat(
      messages: [
        { role: 'user', content: 'Write me a haiku with intensity 0.7.' },
        { role: 'assistant', tool_calls: response.tool_calls },
        {
          role: 'tool',
          tool_call_id: tool_call[:id],
          content: haiku
        }
      ],
      tools: [
        {
          type: 'function',
          function: {
            name: 'haiku',
            description: 'Generate a haiku poem',
            parameters: {
              type: 'object',
              properties: {
                intensity: {
                  type: 'number',
                  minimum: 0.0,
                  maximum: 1.0,
                  description: 'Intensity level of the haiku'
                }
              },
              required: ['intensity']
            }
          }
        }
      ]
    )

    pp '----- FINAL RESPONSE -------'
    pp final_response
    pp '---------------------------'

    expect(final_response.content).to include('salad')
  end
end

#!/usr/bin/env ruby
require 'dotenv/load'
require_relative '../../lib/ralph'

puts "=== Haiku Agent Integration Test ==="
puts ""

agent = Ralph::Agent.new('HAIKU')
puts "Loaded agent: #{agent.name}"
puts "Description: #{agent.description}"
puts "Tools: #{agent.tools.join(', ')}"
puts ""

puts "Calling agent with request: 'Write me a haiku about coding'"
puts ""

response = agent.call('Write me a haiku about coding')
puts "Response:"
puts response
puts ""

puts "=== Test Complete ==="

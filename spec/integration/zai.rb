#!/usr/bin/env ruby
# frozen_string_literal: true
require "dotenv/load"
require_relative "../../lib/crayons"

puts "=== Haiku Agent Integration Test ==="
puts ""

agent = Crayons::Agent.new("HAIKU")
puts "Loaded agent: #{agent.name}"
puts "Description: #{agent.description}"
puts "Tools: #{agent.tools.join(', ')}"
puts ""

puts "Calling agent with request: 'Write me a haiku about coding'"
puts ""

response = agent.call("Write me a haiku about coding")
puts "Response:"
puts response
puts ""

if response.start_with?("SUCCESS:")
  puts "✓ Agent returned SUCCESS"
else
  puts "✗ Agent did not return SUCCESS format"
end

puts ""
puts "=== Test Complete ==="

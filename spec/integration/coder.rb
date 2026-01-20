#!/usr/bin/env ruby
# frozen_string_literal: true
#
# This is a full integration test that checks the system can implement a PRD
require "dotenv/load"
require_relative "../../lib/crayons"

puts "=== Coder Agent Integration Test ==="
puts ""

prd_content = File.read(File.expand_path("../../prds/test-01.md", __dir__))
puts "Test PRD:"
puts prd_content
puts ""

agent = Crayons::Agent.new("MARGE")
puts "Loaded agent: #{agent.name}"
puts "Description: #{agent.description}"
puts "Tools: #{agent.tools.join(', ')}"
puts ""

puts "Calling agent with PRD..."
puts ""

response = agent.call(prd_content)
puts "Response:"
puts response
puts ""

puts "=== Verification ==="
if File.exist?("./hello_world.rb")
  puts "✓ hello_world.rb was created"
  content = File.read("./hello_world.rb")
  puts content

  if content.include?("HelloWorld") && content.include?("hello") && content.include?("Hello, World. I am alive!")
    puts "\n✓ HelloWorld class exists"
    puts "✓ .hello class method exists"
    puts "✓ Returns correct string"
  else
    puts "\n✗ HelloWorld implementation incomplete"
  end
else
  puts "✗ hello_world.rb was not created"
end

puts ""
puts "=== Test Complete ==="

#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Integration test for WILLIE explorer agent through ExploreTool
#
# This test actually runs WILLIE with a real LLM call to verify:
# 1. WILLIE can explore the codebase with a vague task
# 2. It finds relevant files (haiku.rb and haiku_spec.rb)
# 3. It returns structured output with file signposts
#
# Note: This test requires a working LLM API. If the API is unavailable
# or rate-limited, the test will skip gracefully with exit code 0.
require "dotenv/load"
require_relative "../../lib/crayons"

puts "=== WILLIE Explorer Integration Test ==="
puts ""

tool = Crayons::ExploreTool.new
puts "Loaded tool: #{tool.name}"
puts "Description: #{tool.description}"
puts ""

puts "Exploring codebase for haiku information. Use the batch tool for speed."
puts ""

response = tool.execute(problem: "Find information about haikus in this codebase")

# Check if tool returned an error hash
if response.is_a?(Hash) && response[:error]
  puts "Error during exploration: #{response[:error]}"
  puts ""
  puts "=== Skipping test due to API/network issues ==="
  puts "This is expected when the LLM API is unavailable or rate-limited."
  exit 0
end

puts "Response:"
puts response
puts ""

# Skip test if API call failed (network timeout, rate limit, etc.)
if response.start_with?("FAILURE:") && (response.include?("Network") || response.include?("API error"))
  puts "=== Skipping test due to API/network issues ==="
  puts "This is expected when the LLM API is unavailable or rate-limited."
  exit 0
end

puts "=== Verification ==="

haiku_files = ["lib/crayons/tools/haiku.rb", "spec/unit/tools/haiku_spec.rb"]
all_found = true

haiku_files.each do |file|
  if response.include?(file)
    puts "✓ Found reference to #{file}"
  else
    puts "✗ Missing reference to #{file}"
    all_found = false
  end
end

if response.include?("SUCCESS:")
  puts "✓ Response indicates SUCCESS"
else
  puts "✗ Response does not indicate SUCCESS"
  all_found = false
end

# Check that output is in minimal format (file paths with relevance)
# Should NOT have verbose sections like "## Relevant Files" or code blocks
if response.include?("[") && response.include?("] -")
  puts "✓ Response uses minimal file path format"
else
  puts "✗ Response missing minimal file path format"
  all_found = false
end

if response.include?("## Relevant Files") || response.include?("**Type:**") || response.include?("```")
  puts "✗ Response includes verbose formatting (should be minimal)"
  all_found = false
else
  puts "✓ Response avoids verbose formatting"
end

puts ""

if all_found
  puts "=== All Verifications Passed ==="
else
  puts "=== Some Verifications Failed ==="
  exit 1
end

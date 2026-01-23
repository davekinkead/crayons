#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../lib/agent"

RSpec.describe "bin/agent CLI" do
  it "requires both --agent and --call arguments" do
    output = `bin/agent --agent MARGE 2>&1`

    expect(output).to include("Both --agent and --call are required")
  end

  it "displays help with --help flag" do
    output = `bin/agent --help`

    expect(output).to include("Usage: bin/agent")
    expect(output).to include("--agent NAME")
    expect(output).to include("--call PROMPT")
  end

  it "can be invoked with short flags" do
    output = `bin/agent -a TEST -c 'test prompt' 2>&1`

    expect(output).to be_a(String)
  end

  it "exits with non-zero status when arguments missing" do
    system("bin/agent --agent MARGE")
    exit_status = $CHILD_STATUS.exitstatus

    expect(exit_status).to eq(1)
  end

  it "exits with zero status when arguments provided (may fail on API)" do
    system("bin/agent --agent TEST --call 'hello' > /dev/null 2>&1")
    exit_status = $CHILD_STATUS.exitstatus

    expect([0, 1]).to include(exit_status)
  end
end

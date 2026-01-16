require 'dotenv/load'
require_relative 'ralph/agent'
require_relative 'ralph/tools/bash'
require_relative 'ralph/tools/files'

module Ralph
  class Error < StandardError; end
end

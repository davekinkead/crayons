require 'dotenv/load'
require_relative 'ralph/tool'

module Ralph
  module Tools
  end

  class Error < StandardError; end
end

require_relative 'ralph/agent'
require_relative 'ralph/tools/bash'
require_relative 'ralph/tools/haiku'
require_relative 'ralph/tools/read_file'
require_relative 'ralph/tools/write_file'
require_relative 'ralph/tools/edit_file'

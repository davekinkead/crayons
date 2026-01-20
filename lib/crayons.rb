# frozen_string_literal: true
require_relative "crayons/version"
require_relative "crayons/logger"
require_relative "crayons/hello_world"
require_relative "crayons/agent"
require_relative "crayons/tools"
require_relative "crayons/clients/zai"

module Crayons
  class Error < StandardError; end
end

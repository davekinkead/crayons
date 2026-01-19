require_relative "ralph/version"
require_relative "ralph/logger"
require_relative "ralph/agent"
require_relative "ralph/tools"
require_relative "ralph/clients/zai"

module Ralph
  class Error < StandardError; end
end

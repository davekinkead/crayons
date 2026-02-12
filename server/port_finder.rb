# frozen_string_literal: true

require "socket"

module Server
  class PortFinder
    DEFAULT_PORTS = [4567, 4568, 4569, 4570].freeze
    RANDOM_PORT_MIN = 3000
    RANDOM_PORT_MAX = 4000

    def self.find_available_port
      DEFAULT_PORTS.each do |port|
        return port if port_available?(port)
      end

      find_random_port
    end

    def self.port_available?(port)
      server = TCPServer.new("127.0.0.1", port)
      server.close
      true
    rescue Errno::EADDRINUSE, Errno::EACCES
      false
    end

    def self.find_random_port
      loop do
        port = rand(RANDOM_PORT_MIN..RANDOM_PORT_MAX)
        return port if port_available?(port)
      end
    end
  end
end

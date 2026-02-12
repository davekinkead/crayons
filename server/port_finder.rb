# frozen_string_literal: true

require "socket"

module Server
  class PortFinder
    DEFAULT_PORTS = [4567, 4568, 4569, 4570].freeze
    RANDOM_PORT_MIN = 3000
    RANDOM_PORT_MAX = 4000
    MAX_ATTEMPTS = 10

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
      MAX_ATTEMPTS.times do
        port = rand(RANDOM_PORT_MIN..RANDOM_PORT_MAX)
        return port if port_available?(port)
      end
      raise "No available ports in range #{RANDOM_PORT_MIN}-#{RANDOM_PORT_MAX} after #{MAX_ATTEMPTS} attempts"
    end
  end
end

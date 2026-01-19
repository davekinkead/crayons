# frozen_string_literal: true
require "fileutils"
require "logger"

module Ralph
  class Logger
    MAX_CONTEXT_LENGTH = 100

    class << self
      def instance
        @instance ||= new
      end

      def remove_instance
        @instance = nil
      end
    end

    attr_reader :log_file_path, :level

    def initialize
      @log_file_path = determine_log_file_path
      @level = determine_log_level
      @logger = create_logger
    end

    def log(level, agent_id, message)
      return unless @logger

      level_constant = map_level_to_constant(level) if level.is_a?(Symbol)
      actual_level = level_constant || level

      context = truncate_context(agent_id.to_s)
      sanitized_message = sanitize_message(message)
      @logger.add(actual_level, "[#{context}] #{sanitized_message}")
    rescue StandardError => _e
      nil
    end

    def debug(agent_id, message)
      log(::Logger::DEBUG, agent_id, message)
    end

    def info(agent_id, message)
      log(::Logger::INFO, agent_id, message)
    end

    def warn(agent_id, message)
      log(::Logger::WARN, agent_id, message)
    end

    def error(agent_id, message)
      log(::Logger::ERROR, agent_id, message)
    end

    private

    def create_logger
      log_dir = File.dirname(@log_file_path)
      FileUtils.mkdir_p(log_dir)

      logger = ::Logger.new(@log_file_path)
      logger.level = map_level_to_constant(@level)
      logger.formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] [#{severity}] #{msg}\n"
      end
      logger
    rescue StandardError => _e
      nil
    end

    def determine_log_file_path
      ENV["RALPH_LOG_FILE"] || "logs/ralph.log"
    end

    def determine_log_level
      env_var = ENV.fetch("RALPH_LOG_LEVEL", nil)
      return :debug unless env_var
      level = env_var.to_s.downcase.to_sym
      return level if %i[debug info warn error].include?(level)
      :debug
    end

    def map_level_to_constant(level)
      case level
      when :info then ::Logger::INFO
      when :warn then ::Logger::WARN
      when :error then ::Logger::ERROR
      else ::Logger::DEBUG
      end
    end

    def truncate_context(context)
      return context if context.length <= MAX_CONTEXT_LENGTH
      context[0...MAX_CONTEXT_LENGTH]
    end

    def sanitize_message(message)
      message.to_s.gsub(/\r?\n/, " ").squeeze(" ").strip
    end

    def parse_log_level
      env_var = ENV.fetch("RALPH_LOG_LEVEL", nil)
      return :debug unless env_var
      env_var.to_s.downcase.to_sym
    end
  end
end

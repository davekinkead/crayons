# frozen_string_literal: true

original_load_path = $LOAD_PATH.dup
$LOAD_PATH.reject! { |p| p.include?(File.expand_path("..", __dir__)) }
require "logger"
$LOAD_PATH.replace(original_load_path)

require "fileutils"

module Crayons
  class Logger
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3
    MAX_CONTEXT_LENGTH = 100
    MAX_MESSAGE_LENGTH = 500

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

      context = truncate_context(agent_id.to_s)
      truncated_message = truncate_message(message.to_s, level)
      @logger.add(level, "[#{context}] #{truncated_message}")
    end

    def debug(agent_id, message)
      log(DEBUG, agent_id, message)
    end

    def info(agent_id, message)
      log(INFO, agent_id, message)
    end

    def warn(agent_id, message)
      log(WARN, agent_id, message)
    end

    def error(agent_id, message)
      log(ERROR, agent_id, message)
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
    end

    def determine_log_file_path
      ENV["CRAYONS_LOG_FILE"] || "logs/crayons.log"
    end

    def determine_log_level
      env_var = ENV.fetch("CRAYONS_LOG_LEVEL", nil)
      return DEBUG unless env_var
      level = env_var.to_s.downcase.to_sym
      level if %i[debug info warn error].include?(level) || DEBUG
    end

    def map_level_to_constant(level)
      case level
      when :info then INFO
      when :warn then WARN
      when :error then ERROR
      else DEBUG
      end
    end

    def truncate_context(context)
      return context if context.length <= MAX_CONTEXT_LENGTH
      context[0...MAX_CONTEXT_LENGTH]
    end

    def truncate_message(message, level)
      return message if level == ERROR
      return message if message.length <= MAX_MESSAGE_LENGTH
      message[0...MAX_MESSAGE_LENGTH]
    end
  end
end

require 'active_support/core_ext/module/delegation'

module WebsocketRails
  module Logging
    # Logging module heavily influenced by Travis-Support library

    ANSI = {
      :red    => 31,
      :green  => 32,
      :yellow => 33,
      :cyan   => 36
    }

    class << self
      def configure(logger)
        logger.tap do
          logger.formatter = proc { |*args| Format.format(*args) }
          logger.level = Logger.const_get(log_level.to_s.upcase)
        end
      end

      def log_level
        WebsocketRails.log_level || :debug
      end
    end

    delegate :logger, :to => WebsocketRails

    [:fatal, :error, :warn, :info, :debug].each do |level|
      define_method(level) do |*args|
        message, options = *args
        log(level, message, options)
      end
    end

    def log(level, message, options = {})
      message.chomp.split("\n").each do |line|
        logger.send(level, wrap(level, self, line, options || {}))
      end
    end

    def log_exception(exception)
      logger.error(wrap(:error, self, "#{exception.class.name}: #{exception.message}"))
      exception.backtrace.each { |line| logger.error(wrap(:error, self, line)) } if exception.backtrace
    rescue Exception => e
      puts '--- FATAL ---'
      puts 'an exception occured while logging an exception'
      puts e.message, e.backtrace
      puts exception.message, exception.backtrace
    end

    def wrap(level, object, message, options = {})
      header = options[:header] || object.log_header
      color = color_for_level(level)
      "[#{colorize(color, header)}] #{message.chomp}"
    end

    def colorize(color, text)
      "\e[#{ANSI[color]}m#{text}\e[0m"
    end

    def color_for_level(level)
      case level
      when :info then :green
      when :debug then :yellow
      else
        :red
      end
    end

    def log_header
      self.class.name.split('::').last
    end

    module Format
      class << self
        def format(severity, time, progname, msg)
          "#{severity[0, 1]} [#{format_time(time)}] #{msg}\n"
        end

        def format_time(time)
          time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0, 3]
        end
      end
    end

  end
end

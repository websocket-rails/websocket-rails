module WebsocketRails
  # Need to replace this module with a real logger
  module Logging

    def self.included(base)
      base.extend ClassMethods
    end

    def log(msg)
      puts msg if debug?
    end

    def warn(msg)
      puts msg
    end

    def debug?
      WebsocketRails.log_level == :debug
    end

    module ClassMethods

      def log(msg)
        puts msg if debug?
      end

      def debug?
        WebsocketRails.log_level == :debug
      end

    end

  end
end

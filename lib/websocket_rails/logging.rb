module WebsocketRails
  # Need to replace this module with a real logger
  module Logging
    
    def log(msg)
      puts msg if debug?
    end

    def warn(msg)
      puts msg
    end

    def debug?
      LOG_LEVEL == :debug
    end

  end
end

module WebsocketRails
  class Configuration

    def route_block=(routes)
      @event_routes = routes
    end

    def route_block
      @event_routes
    end

    def log_level
      @log_level ||= begin
        case Rails.env.to_sym
        when :production then :info
        when :development then :debug
        end
      end
    end

    def log_level=(level)
      @log_level = level
    end

    def logger
      @logger ||= begin
        logger = Logger.new(log_path)
        Logging.configure(logger)
      end
    end

    def logger=(logger)
      @logger = logger
    end

    def log_path
      @log_path ||= "#{Rails.root}/log/websocket_rails.log"
    end

    def log_path=(path)
      @log_path = path
    end

    def log_internal_events?
      @log_internal_events ||= false
    end

    def log_internal_events=(value)
      @log_internal_events = value
    end

    def synchronize
      @synchronize ||= false
    end

    def synchronize=(synchronize)
      @synchronize = synchronize
    end

    def redis_options
      @redis_options ||= redis_defaults
    end

    def redis_options=(options = {})
      @redis_options = redis_defaults.merge(options)
    end

    def redis_defaults
      {:host => '127.0.0.1', :port => 6379, :driver => :ruby}
    end

    def standalone
      @standalone ||= false
    end

    def standalone=(standalone)
      @standalone = standalone
    end

    def standalone_port
      @standalone_port ||= '3001'
    end

    def standalone_port=(port)
      @standalone_port = port
    end

    def thin_options
      @thin_options ||= thin_defaults
    end

    def thin_options=(options = {})
      @thin_options = thin_defaults.merge(options)
    end

    def thin_defaults
      {
        :port => standalone_port,
        :pid => "#{Rails.root}/tmp/pids/websocket_rails.pid",
        :log => "#{Rails.root}/log/websocket_rails_server.log",
        :tag => 'websocket_rails',
        :rackup => "#{Rails.root}/config.ru",
        :threaded => false,
        :daemonize => true,
        :dirname => Rails.root,
        :max_persistent_conns => 1024,
        :max_conns => 1024
      }
    end

  end
end

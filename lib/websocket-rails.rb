require "active_support/dependencies"
require "logger"
require "thin"

module WebsocketRails
  mattr_accessor :app_root

  def self.setup
    yield self
  end

  def self.route_block=(routes)
    @event_routes = routes
  end

  def self.route_block
    @event_routes
  end

  def self.log_level
    @log_level ||= begin
      case Rails.env.to_sym
      when :production then :info
      when :development then :debug
      end
    end
  end

  def self.log_level=(level)
    @log_level = level
  end

  def self.logger
    @logger ||= begin
      logger = Logger.new(log_path)
      Logging.configure(logger)
    end
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.log_path
    @log_path ||= "#{Rails.root}/log/websocket_rails.log"
  end

  def self.log_path=(path)
    @log_path = path
  end

  attr_accessor :synchronize
  module_function :synchronize, :synchronize=

  def self.synchronize?
    (@synchronize == true) || (@standalone == true)
  end

  def self.redis_options
    @redis_options ||= redis_defaults
  end

  def self.redis_options=(options = {})
    @redis_options = redis_defaults.merge(options)
  end

  def self.redis_defaults
    {:host => '127.0.0.1', :port => 6379, :driver => :synchrony}
  end

  attr_accessor :standalone
  module_function :standalone, :standalone=

  def self.standalone?
    @standalone == true
  end

  def self.standalone_port
    @standalone_port ||= '3001'
  end

  def self.standalone_port=(port)
    @standalone_port = port
  end

  def self.thin_options
    @thin_options ||= thin_defaults
  end

  def self.thin_options=(options = {})
    @thin_options = thin_defaults.merge(options)
  end

  def self.thin_defaults
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

require 'websocket_rails/engine'
require 'websocket_rails/logging'
require 'websocket_rails/synchronization'
require 'websocket_rails/connection_manager'
require 'websocket_rails/dispatcher'
require 'websocket_rails/controller_factory'
require 'websocket_rails/event'
require 'websocket_rails/event_map'
require 'websocket_rails/event_queue'
require 'websocket_rails/channel'
require 'websocket_rails/channel_manager'
require 'websocket_rails/base_controller'
require 'websocket_rails/internal_events'

require 'websocket_rails/connection_adapters'
require 'websocket_rails/connection_adapters/http'
require 'websocket_rails/connection_adapters/web_socket'

# Exceptions
class WebsocketRails::InvalidConnectionError < StandardError
  def rack_response
    [400,{'Content-Type' => 'text/plain'},['invalid connection']]
  end
end

class WebsocketRails::EventRoutingError < StandardError

  attr_reader :event, :controller, :method

  def initialize(event, controller, method)
    @event = event
    @controller = controller
  end

  def to_s
    out =  "Routing Error:\n"
    out << "Event: #{event.name}\n"
    out << "Controller #{controller.class} does not respond to #{method}"
    out
  end

  def to_json
    super({
      error: "EventRoutingError",
      event: event.name,
      method: method,
      reason: "Controller #{controller.class} does not respond to #{method}"
    })
  end

end

# Deprecation Notices
class WebsocketRails::Dispatcher
  def self.describe_events(&block)
    raise "This method has been deprecated. Please use WebsocketRails::EventMap.describe instead."
  end
end
class WebsocketRails::Events
  def self.describe_events(&block)
    raise "This method has been deprecated. Please use WebsocketRails::EventMap.describe instead."
  end
end
class WebsocketRails::InitializeSessionDeprecated < StandardError
  def to_s
    "`#initialize_session` has been deprecated. Please use #initialize instead."
  end

  def to_json
    super({
      error: "#initialize_session has been deprecated. Please use #initialize instead.",
    })
  end
end

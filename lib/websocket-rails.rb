require "active_support/dependencies"
require 'thin'

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
    @log_level ||= :warn
  end

  def self.log_level=(level)
    @log_level = level
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
    {:host => '127.0.0.1', :port => 6379}
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
      :log => "#{Rails.root}/log/websocket_rails.log",
      :tag => 'websocket_rails',
      :rackup => "#{Rails.root}/config.ru",
      :threaded => true,
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
class InvalidConnectionError < StandardError
  def rack_response
    [400,{'Content-Type' => 'text/plain'},['invalid connection']]
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

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
end

require "websocket_rails/engine"
require 'websocket_rails/connection_manager'
require 'websocket_rails/dispatcher'
require 'websocket_rails/events'
require 'websocket_rails/base_controller'

::Thin::Server.send( :remove_const, 'DEFAULT_TIMEOUT' )
::Thin::Server.const_set( 'DEFAULT_TIMEOUT', 0 )
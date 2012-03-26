require "active_support/dependencies"

module WebsocketRails
  mattr_accessor :app_root
  
  def self.setup
    yield self
  end
  
end

require "websocket_rails/engine"
require 'websocket_rails/connection_manager'
require 'websocket_rails/dispatcher'
require 'websocket_rails/base_controller'
require 'websocket_rails/extensions/common'

WebsocketRails::Extensions::Common.apply!
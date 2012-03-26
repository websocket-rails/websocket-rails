require "active_support/dependencies"

module WebsocketRails
  mattr_accessor :app_root
  
  def self.setup
    yield self
  end
  
end

require "websocket_rails/engine"
$LOAD_PATH.unshift(Dir.pwd)

require "config/environment"
require "websocket-rails"
#require "config/initializers/websocket_rails.rb"
#require "config/events.rb"

run WebsocketRails.connection_manager

$LOAD_PATH.unshift(Dir.pwd)

require "config/environment"
require "websocket-rails"

run WebsocketRails.connection_manager

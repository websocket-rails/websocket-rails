require "active_support/dependencies"
require "logger"
require "thin"

module WebsocketRails

  class << self
    def setup
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def synchronize?
      config.synchronize == true || config.standalone == true
    end

    def standalone?
      config.standalone == true
    end

    def logger
      config.logger
    end
  end

end

require 'websocket_rails/engine'

require 'websocket_rails/configuration'
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
      :error => "EventRoutingError",
      :event => event.name,
      :method => method,
      :reason => "Controller #{controller.class} does not respond to #{method}"
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

require 'json'

module WebsocketRails
  module HelperMethods
    def env
      @_env ||= Rack::MockRequest.env_for('/websocket')
    end

    def encoded_message
      [234234234234,'test_event',{user_name: 'Joe User'}].to_json
    end

    MockEvent = Struct.new(:data)
  end
end

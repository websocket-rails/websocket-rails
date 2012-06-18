require 'json'

module WebsocketRails
  module HelperMethods
    def env
      @_env ||= begin
        env = Rack::MockRequest.env_for('/websocket')
        env['async.callback'] = Proc.new { |response| true }
        env
      end
    end

    def encoded_message
      ['test_event',{user_name: 'Joe User'}].to_json
    end

    def received_encoded_message(connection_id)
      [connection_id,'test_event',{user_name: 'Joe User'}].to_json
    end

    MockEvent = Struct.new(:data)
  end
end

module EM
  def self.next_tick(&block)
    block.call if block.respond_to?(:call)
  end
end

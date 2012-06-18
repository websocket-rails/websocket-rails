require 'json'

module WebsocketRails
  class Event

    def self.new_from_json(encoded_data,connection)
      event_name, data = decode encoded_data
      Event.new event_name, data, connection
    end

    def self.new_on_open(connection,data=nil)
      Event.new :client_connected, data, connection
    end

    def self.new_on_close(connection,data=nil)
      Event.new :client_disconnected, data, connection
    end

    def self.new_on_error(connection,data=nil)
      Event.new :client_error, data, connection
    end

    attr_reader :name, :data, :connection

    def initialize(event_name,data,connection)
      @name = event_name.to_sym
      @data = data.is_a?(Hash) ? data.with_indifferent_access : data
      @connection = connection
    end

    def serialize
      [connection.id, name, data].to_json
    end

    private

    def self.decode(encoded_data)
      message = JSON.parse( encoded_data )
      event_name = message[0]
      data = message[1]
      data['received'] = Time.now if data.is_a?(Hash)
      [event_name,data]
    end

  end
end

require 'json'

module WebsocketRails
  class Event

    def self.new_from_json(encoded_data,connection)
      event_name, data, namespace = decode encoded_data
      Event.new event_name, data, :connection => connection, :namespace => namespace
    end

    def self.new_on_open(connection,data=nil)
      connection_id = { :connection_id => connection.id }
      on_open_data  = data.is_a?(Hash) ? data.merge(connection_id) : connection_id

      Event.new :client_connected, on_open_data, :connection => connection
    end

    def self.new_on_close(connection,data=nil)
      Event.new :client_disconnected, data, :connection => connection
    end

    def self.new_on_error(connection,data=nil)
      Event.new :client_error, data, :connection => connection
    end

    attr_reader :name, :data, :connection, :namespace

    def initialize(event_name,data,options={})
      @name = event_name.to_sym
      @data = data.is_a?(Hash) ? data.with_indifferent_access : data
      @connection = options[:connection]
      validate_namespace options[:namespace]
    end

    def serialize
      [encoded_name, data].to_json
    end

    private

    def validate_namespace(namespace)
      namespace = [namespace] unless namespace.is_a?(Array)
      namespace.unshift :global unless namespace.first == :global
      @namespace = namespace.map(&:to_sym) rescue [:global]
    end

    def encoded_name
      if namespace.size > 1
        child_namespace = namespace.dup[1..-1]
        child_namespace << name
        combined_name = child_namespace.join('.')
      else
        combined_name = name
      end
      combined_name
    end

    def self.decode(encoded_data)
      message    = JSON.parse( encoded_data )
      event_name = message[0]
      data       = message[1]

      namespace  = event_name.split('.')
      event_name = namespace.pop

      data['received'] = Time.now if data.is_a?(Hash)
      [event_name,data,namespace]
    end

  end
end

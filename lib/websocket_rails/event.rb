require 'json'

module WebsocketRails
  class Event

    def self.new_from_json(encoded_data,connection)
      event_name, data, namespace, channel = decode encoded_data
      Event.new event_name, data, 
        :connection => connection,
        :namespace => namespace,
        :channel => channel
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

    attr_reader :name, :data, :connection, :namespace, :channel

    def initialize(event_name,data,options={})
      @name       = event_name.to_sym
      @data       = data.is_a?(Hash) ? data.with_indifferent_access : data
      @channel    = options[:channel]
      @connection = options[:connection]
      @namespace  = validate_namespace options[:namespace]
    end

    def serialize
      if is_channel?
        [channel, encoded_name, data].to_json
      else
        [encoded_name, data].to_json
      end
    end

    def is_channel?
      !@channel.nil?
    end

    private

    def validate_namespace(namespace)
      namespace = [namespace] unless namespace.is_a?(Array)
      namespace.unshift :global unless namespace.first == :global
      namespace.map(&:to_sym) rescue [:global]
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
      message = JSON.parse( encoded_data )

      channel_name = message.shift if message.size == 3
      event_name   = message[0]
      data         = message[1]

      namespace  = event_name.split('.')
      event_name = namespace.pop

      data['received'] = Time.now if data.is_a?(Hash)
      [event_name, data, namespace, channel_name]
    end

  end
end

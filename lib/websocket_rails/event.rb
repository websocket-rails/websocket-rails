module WebsocketRails

  module StaticEvents

    def new_on_open(connection,data=nil)
      connection_id = {
        :connection_id => connection.id
      }
      data = data.is_a?(Hash) ? data.merge( connection_id ) : connection_id
      Event.new :client_connected, :data => data, :connection => connection
    end

    def new_on_close(connection,data=nil)
      Event.new :client_disconnected, :data => data, :connection => connection
    end

    def new_on_error(connection,data=nil)
      Event.new :client_error, :data => data, :connection => connection
    end

    def new_on_ping(connection)
      Event.new :ping, :data => {}, :connection => connection, :namespace => :websocket_rails
    end

  end

  # Contains all of the relevant information for incoming and outgoing events.
  # All events except for channel events will have a connection object associated.
  #
  # Events require an event name and hash of options:
  #
  # :data =>
  # The data object will be passed to any callback functions bound on the
  # client side.
  #
  # You can also pass a Hash of options to specify:
  #
  # :connection =>
  # Connection that will be receiving or that sent this event.
  #
  # :namespace =>
  # The namespace this event is under. Will default to :global
  # If the namespace is nested under multiple levels pass them as an array.
  # For instance, if the namespace route looks like the following:
  #
  #   namespace :products do
  #     namespace :hats do
  #       # events
  #     end
  #   end
  #
  # Then you would pass the namespace argument as [:products,:hats]
  #
  # :channel =>
  # The name of the channel that this event is destined for.
  class Event

    def self.new_from_json(encoded_data,connection)
      event_name, data = JSON.parse encoded_data
      data = data.merge(:connection => connection).with_indifferent_access
      Event.new event_name, data
    rescue JSON::ParserError => ex
      warn "Invalid Event Received: #{ex}"
    end

    include Logging
    extend StaticEvents

    attr_reader :id, :name, :connection, :namespace, :channel

    attr_accessor :data, :result, :success

    def initialize(event_name,options={})
      case event_name
      when String
        namespace = event_name.split('.')
        @name     = namespace.pop.to_sym
      when Symbol
        @name     = event_name
        namespace = [:global]
      end
      @id         = options[:id]
      @data       = options[:data].is_a?(Hash) ? options[:data].with_indifferent_access : options[:data]
      @channel    = options[:channel].to_sym if options[:channel]
      @connection = options[:connection]
      @namespace  = validate_namespace( options[:namespace] || namespace )
    end

    def serialize
      [
        encoded_name,
        {
          :id => id,
          :channel => channel,
          :data => data,
          :success => success,
          :result => result
        }
      ].to_json
    end

    def is_channel?
      !@channel.nil?
    end

    def trigger
      connection.trigger self if connection
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

  end
end

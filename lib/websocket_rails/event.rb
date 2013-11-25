module WebsocketRails

  module StaticEvents

    def new_on_open(connection, data=nil)
      connection_id = {
        :connection_id => connection.id.to_s
      }
      data = data.is_a?(Hash) ? data.merge( connection_id ) : connection_id
      Event.new :client_connected, data, :connection => connection
    end

    def new_on_close(connection, data=nil)
      Event.new :client_disconnected, data, :connection => connection
    end

    def new_on_error(connection, data=nil)
      Event.new :client_error, data, :connection => connection
    end

    def new_on_invalid_event_received(connection, data=nil)
      Event.new :invalid_event, data, :connection => connection
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
  class Event < Message

    class UnknownDataType < StandardError; end;

    def self.log_header
      "Event"
    end

    def self.deserialize(encoded_data, connection)
      case encoded_data
      when String
        event_name, data, options = JSON.parse(encoded_data)

        if options.is_a?(Hash)
          options = options.merge(connection: connection).with_indifferent_access
        else
          options = {connection: connection}.with_indifferent_access
        end

        Event.new event_name, data, options
        # when Array
        # TODO: Handle file
        #File.open("/tmp/test#{rand(100)}.jpg", "wb") do |file|
        #  encoded_data.each do |byte|
        #    file << byte.chr
        #  end
        #end
      else
        raise UnknownDataType
      end
    rescue JSON::ParserError, UnknownDataType => ex
      warn "Invalid Event Received: #{ex}"
      debug "Event Data: #{encoded_data}"
      log_exception(ex)
      Event.new_on_invalid_event_received(connection, nil)
    end

    extend StaticEvents

    attr_reader :id, :name, :connection, :namespace, :channel,
                :user_id, :token

    attr_accessor :data, :result, :success, :server_token, :propagate

    def initialize(event_name, data = nil, options = {})
      case event_name
      when String
        namespace   = event_name.split('.')
        @name       = namespace.pop.to_sym
      when Symbol
        @name       = event_name
        namespace   = [:global]
      end
      @data         = data.is_a?(Hash) ? data.with_indifferent_access : data
      @id           = options[:id]

      # TODO: Channel names can be untrusted input.
      # They need to be sanitized better.
      @channel      = options[:channel].to_sym rescue options[:channel].to_s.to_sym if options[:channel]

      @token        = options[:token]
      @connection   = options[:connection]
      @server_token = options[:server_token]
      @user_id      = options[:user_id]
      @propagate    = options[:propagate].nil? ? true : options[:propagate]
      @namespace    = validate_namespace( options[:namespace] || namespace )
      @type         = options[:type] || set_event_type
    end

    def type
      @type
    end

    def as_json
      [
        encoded_name,
        data,
        {
          :id => id,
          :channel => channel,
          :user_id => user_id,
          :success => success,
          :result => result,
          :token => token,
          :server_token => server_token
        }
      ]
    end

    def protocol
      connection.protocol
    end

    def serialize
      as_json.to_json
    end

    def is_channel?
      @type == :channel
    end

    def is_user?
      @type == :user
    end

    def is_invalid?
      @type == :invalid
    end

    def is_internal?
      @type == :internal
    end

    def should_propagate?
      @propagate
    end

    def trigger
      connection.trigger self if connection
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

    private

    def set_event_type
      case
      when @channel.present?
        @type = :channel
      when namespace.include?(:websocket_rails)
        @type = :internal
      when name == :invalid_event
        @type = :invalid
      when @user_id.present?
        @type = :user
      else
        @type = :default
      end
    end

    def validate_namespace(namespace)
      namespace = [namespace] unless namespace.is_a?(Array)
      namespace.unshift :global unless namespace.first == :global
      namespace.map(&:to_sym) rescue [:global]
    end

  end
end

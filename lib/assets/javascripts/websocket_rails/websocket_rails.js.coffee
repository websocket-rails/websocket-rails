###
WebsocketRails JavaScript Client

Setting up the dispatcher:
  var dispatcher = new WebSocketRails('localhost:3000');
  dispatcher.on_open = function() {
    // trigger a server event immediately after opening connection
    dispatcher.trigger('new_user',{user_name: 'guest'});
  })

Triggering a new event on the server
  dispatcherer.trigger('event_name',object_to_be_serialized_to_json);

Listening for new events from the server
  dispatcher.bind('event_name', function(data) {
    console.log(data.user_name);
  });
###
class window.WebSocketRails
  constructor: (@url, @use_websockets = true) ->
    @state          = 'connecting'
    @callbacks      = {}
    @channels       = {}

    unless @supports_websockets() and @use_websockets
      @_conn = new WebSocketRails.HttpConnection url, @
    else
      @_conn = new WebSocketRails.WebSocketConnection url, @

    @_conn.new_message = @new_message

  new_message: (data) =>
    for socket_message in data
      if socket_message.length > 2
        event_name = socket_message[1]
        message    = socket_message[2]
        @dispatch_channel socket_message...
      else
        event_name = socket_message[0]
        message    = socket_message[1]
        @dispatch socket_message...

      if @state == 'connecting' and event_name == 'client_connected'
        @connection_established message

  connection_established: (data) =>
    @state         = 'connected'
    @connection_id = data.connection_id
    if @on_open?
      @on_open(data)

  bind: (event_name, callback) =>
    @callbacks[event_name] ?= []
    @callbacks[event_name].push callback

  trigger: (event_name, data) =>
    @_conn.trigger event_name, data, @connection_id

  dispatch: (event_name, data) =>
    return unless @callbacks[event_name]?
    for callback in @callbacks[event_name]
      callback data

  subscribe: (channel_name) =>
    unless @channels[channel_name]?
      channel = new WebSocketRails.Channel channel_name, @
      @channels[channel_name] = channel
      channel
    else
      @channels[channel_name]

  trigger_channel: (channel, event_name, data) =>
    @_conn.trigger_channel channel, event_name, @connection_id

  dispatch_channel: (channel, event_name, message) =>
    return unless @channels[channel]?
    @channels[channel].dispatch event_name, message

  supports_websockets: =>
    (typeof(WebSocket) == "function" or typeof(WebSocket) == "object")


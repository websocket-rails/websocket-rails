###
WebsocketRails JavaScript Client

Setting up the dispatcher:
  var dispatcher = new WebSocketRails('localhost:3000/websocket');
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
    @state     = 'connecting'
    @callbacks = {}
    @channels  = {}
    @queue     = {}

    unless @supports_websockets() and @use_websockets
      @_conn = new WebSocketRails.HttpConnection url, @
    else
      @_conn = new WebSocketRails.WebSocketConnection url, @

    @_conn.new_message = @new_message

  new_message: (data) =>
    for socket_message in data
      event = new WebSocketRails.Event( socket_message )
      if event.is_result()
        @queue[event.id]?.run_callbacks(event.success, event.data)
        @queue[event.id] = null
      else if event.is_channel()
        @dispatch_channel event
      else if event.is_ping()
        @pong()
      else
        @dispatch event

      if @state == 'connecting' and event.name == 'client_connected'
        @connection_established event.data

  connection_established: (data) =>
    @state         = 'connected'
    @connection_id = data.connection_id
    @_conn.flush_queue data.connection_id
    if @on_open?
      @on_open(data)

  bind: (event_name, callback) =>
    @callbacks[event_name] ?= []
    @callbacks[event_name].push callback

  trigger: (event_name, data, success_callback, failure_callback) =>
    event = new WebSocketRails.Event( [event_name, data, @connection_id], success_callback, failure_callback )
    @queue[event.id] = event
    @_conn.trigger event

  trigger_event: (event) =>
    @queue[event.id] ?= event # Prevent replacing an event that has callbacks stored
    @_conn.trigger event

  dispatch: (event) =>
    return unless @callbacks[event.name]?
    for callback in @callbacks[event.name]
      callback event.data

  subscribe: (channel_name) =>
    unless @channels[channel_name]?
      channel = new WebSocketRails.Channel channel_name, @
      @channels[channel_name] = channel
      channel
    else
      @channels[channel_name]

  subscribe_private: (channel_name) =>
    unless @channels[channel_name]?
      channel = new WebSocketRails.Channel channel_name, @, true
      @channels[channel_name] = channel
      channel
    else
      @channels[channel_name]

  unsubscribe: (channel_name) =>
    return unless @channels[channel_name]?
    channel = @channels[channel_name]
    channel.destroy
    delete @channels[channel_name]

  dispatch_channel: (event) =>
    return unless @channels[event.channel]?
    @channels[event.channel].dispatch event.name, event.data

  supports_websockets: =>
    (typeof(WebSocket) == "function" or typeof(WebSocket) == "object")

  pong: =>
    pong = new WebSocketRails.Event( ['websocket_rails.pong',{},@connection_id] )
    @_conn.trigger pong

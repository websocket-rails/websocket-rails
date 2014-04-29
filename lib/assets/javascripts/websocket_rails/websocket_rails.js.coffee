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

Stop listening for new events from the server
  dispatcher.unbind('event')
###
class @WebSocketRails
  constructor: (@url, @use_websockets = true) ->
    @callbacks = {}
    @channels  = {}
    @queue     = {}

    @connect()

  connect: ->
    @state = 'connecting'

    @_conn = new WebSocketRails.Connection @url, this

    @_conn.new_message = @new_message

  disconnect: ->
    if @_conn
      @_conn.close()
      delete @_conn._conn
      delete @_conn

    @state = 'disconnected'

  # Reconnects the whole connection,
  # keeping the messages queue and its' connected channels.
  #
  # After successfull connection, this will:
  # - reconnect to all channels, that were active while disconnecting
  # - resend all events from which we haven't received any response yet
  reconnect: =>
    old_connection_id = @_conn?.connection_id

    @disconnect()
    @connect()

    # Resend all unfinished events from the previous connection.
    for id, event of @queue
      if event.connection_id == old_connection_id && !event.is_result()
        @trigger_event event

    @reconnect_channels()

  new_message: (data) =>
    event = new WebSocketRails.Event(data)
    if event.is_result()
      @queue[event.id]?.run_callbacks(event.success, event.data)
      delete @queue[event.id]
    else if event.is_channel()
      @dispatch_channel event
    else
      @dispatch event

    if @state == 'connecting' and event.name == 'client_connected'
      @connection_established event

  connection_established: (event) =>
    @state = 'connected'
    @_conn.setConnectionId(event.connection_id)
    @_conn.flush_queue()
    if @on_open?
      @on_open(event.data)

  bind: (event_name, callback) =>
    @callbacks[event_name] ?= []
    @callbacks[event_name].push callback

  unbind: (event_name) =>
    delete @callbacks[event_name]

  trigger: (event_name, data, success_callback, failure_callback) =>
    event = new WebSocketRails.Event([event_name, data, {connection_id: @connection_id}], success_callback, failure_callback)
    @queue[event.id] = event
    @_conn.trigger event

  trigger_event: (event) =>
    @queue[event.id] ?= event # Prevent replacing an event that has callbacks stored
    @_conn.trigger event if @_conn
    event

  dispatch: (event) =>
    return unless @callbacks[event.name]?
    for callback in @callbacks[event.name]
      callback event.data

  subscribe: (channel_name, success_callback, failure_callback) =>
    unless @channels[channel_name]?
      channel = new WebSocketRails.Channel channel_name, @, false, success_callback, failure_callback
      @channels[channel_name] = channel
      channel
    else
      @channels[channel_name]

  subscribe_private: (channel_name, success_callback, failure_callback) =>
    unless @channels[channel_name]?
      channel = new WebSocketRails.Channel channel_name, @, true, success_callback, failure_callback
      @channels[channel_name] = channel
      channel
    else
      @channels[channel_name]

  unsubscribe: (channel_name) =>
    return unless @channels[channel_name]?
    @channels[channel_name].destroy()
    delete @channels[channel_name]

  dispatch_channel: (event) =>
    return unless @channels[event.channel]?
    @channels[event.channel].dispatch event.name, event.data

  supports_websockets: =>
    (typeof(WebSocket) == "function" or typeof(WebSocket) == "object")

  connection_stale: =>
    @state != 'connected'

  # Destroy and resubscribe to all existing @channels.
  reconnect_channels: ->
    for name, channel of @channels
      callbacks = channel._callbacks
      channel.destroy()
      delete @channels[name]

      channel = if channel.is_private
        @subscribe_private name
      else
        @subscribe name
      channel._callbacks = callbacks
      channel

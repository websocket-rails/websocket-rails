###
The channel object is returned when you subscribe to a channel.

For instance:
  var dispatcher = new WebSocketRails('localhost:3000/websocket');
  var awesome_channel = dispatcher.subscribe('awesome_channel');
  awesome_channel.bind('event', function(data) { console.log('channel event!'); });
  awesome_channel.trigger('awesome_event', awesome_object);
###
class WebSocketRails.Channel

  constructor: (@name,@_dispatcher,@is_private) ->
    if @is_private
      event_name = 'websocket_rails.subscribe_private'
    else
      event_name = 'websocket_rails.subscribe'

    event = new WebSocketRails.Event( [event_name, {data: {channel: @name}},@_dispatcher.connection_id], @_success_launcher, @_failure_launcher)
    @_dispatcher.trigger_event event
    @_callbacks = {}
    @_token = undefined
    @_queue = []

  destroy: () =>
    event_name = 'websocket_rails.unsubscribe'
    event =  new WebSocketRails.Event( [event_name, {data: {channel: @name}}, @_dispatcher.connection_id] )
    @_dispatcher.trigger_event event
    @_callbacks = {}

  bind: (event_name, callback) =>
    @_callbacks[event_name] ?= []
    @_callbacks[event_name].push callback

  trigger: (event_name, message) =>
    event = new WebSocketRails.Event( [event_name, {channel: @name, data: message, token: @_token}, @_dispatcher.connection_id] )
    if !@_token
      @_queue.push event
    else
      @_dispatcher.trigger_event event

  dispatch: (event_name, message) =>
    if event_name == 'websocket_rails.channel_token'
      @_token = message['token']
      for event in @_queue
        @_dispatcher.trigger_event event
      @_queue = []
    else
      return unless @_callbacks[event_name]?
      for callback in @_callbacks[event_name]
        callback message

  # using this method because @on_success will not be defined when the constructor is executed
  _success_launcher: (data) =>
    @on_success(data) if @on_success?

  # using this method because @on_failure will not be defined when the constructor is executed
  _failure_launcher: (data) =>
    @on_failure(data) if @on_failure?

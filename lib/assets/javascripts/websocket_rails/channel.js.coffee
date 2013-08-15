###
The channel object is returned when you subscribe to a channel.

For instance:
  var dispatcher = new WebSocketRails('localhost:3000/websocket');
  var awesome_channel = dispatcher.subscribe('awesome_channel');
  awesome_channel.bind('event', function(data) { console.log('channel event!'); });
  awesome_channel.trigger('awesome_event', awesome_object);
###
class WebSocketRails.Channel

  constructor: (@name, @_dispatcher, @is_private) ->
    @_eventQueue = []

    if @is_private
      eventName = 'websocket_rails.subscribe_private'
    else
      eventName = 'websocket_rails.subscribe'

    eventParams = [
      eventName,
      data: {channel: @name},
      @_dispatcher.connection_id
    ]
    event = new WebSocketRails.Event(eventParams, @_success_launcher, @_failure_launcher)

    @_dispatcher.trigger_event event
    @_callbacks = {}

  destroy: =>
    attributes = data: {channel: @name}
    eventParams = [
      'websocket_rails.unsubscribe',
      attributes,
      @_dispatcher.connection_id
    ]
    event = new WebSocketRails.Event(eventParams)

    @_dispatcher.trigger_event event
    @_callbacks = {}

  bind: (eventName, callback) =>
    @_callbacks[eventName] ?= []
    @_callbacks[eventName].push callback

  trigger: (eventName, message) =>
    attributes = {channel: @name, data: message}
    eventParams = [eventName, attributes, @_dispatcher.connection_id]
    event = new WebSocketRails.Event(eventParams)

    if @_token?
      @_dispatcher.trigger_event event
    else
      @_eventQueue.push event

  dispatch: (eventName, message) =>
    return unless @_callbacks[eventName]?
    for callback in @_callbacks[eventName]
      callback message

  # using this method because @on_success will not be defined when the constructor is executed
  _success_launcher: (data) =>
    @on_success(data) if @on_success?

  # using this method because @on_failure will not be defined when the constructor is executed
  _failure_launcher: (data) =>
    @on_failure(data) if @on_failure?

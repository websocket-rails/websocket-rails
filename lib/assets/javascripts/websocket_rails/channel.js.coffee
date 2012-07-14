###
The channel object is returned when you subscribe to a channel.

For instance:
  var dispatcher = new WebSocketRails('localhost:3000/websocket');
  var awesome_channel = dispatcher.subscribe('awesome_channel');
  awesome_channel.bind('event', function(data) { console.log('channel event!'); });
  awesome_channel.trigger('awesome_event', awesome_object);
###
class WebSocketRails.Channel

  constructor: (@name,@dispatcher,is_private) ->
    if is_private
      event_name = 'websocket_rails.subscribe_private'
    else
      event_name = 'websocket_rails.subscribe'

    event = new WebSocketRails.Event( [event_name, {data: {channel: @name}}], @on_success_launcher, @on_failure_launcher)
    @dispatcher.trigger_event event
    @callbacks = {}

  bind: (event_name, callback) =>
    @callbacks[event_name] ?= []
    @callbacks[event_name].push callback

  trigger: (event_name, message) =>
    event = new WebSocketRails.Event( [event_name, {channel: @name, data: message}] )
    @dispatcher.trigger_event event

  dispatch: (event_name, message) =>
    return unless @callbacks[event_name]?
    for callback in @callbacks[event_name]
      callback message
  
  # using this method because @on_success will not be defined when the constructor is executed
  on_success_launcher: (data) =>
    @on_success(data)
    
  # using this method because @on_failure will not be defined when the constructor is executed
  on_failure_launcher: (data) =>
    @on_failure(data)

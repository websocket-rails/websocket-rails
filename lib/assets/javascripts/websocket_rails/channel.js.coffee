###
The channel object is returned when you subscribe to a channel.

For instance:
  var dispatcher = new WebSocketRails('localhost:3000/websocket');
  var awesome_channel = dispatcher.subscribe('awesome_channel');
  awesome_channel.bind('event', function(data) { console.log('channel event!'); });
  awesome_channel.trigger('awesome_event', awesome_object);
###
class WebSocketRails.Channel

  constructor: (@name,@dispatcher) ->
    @dispatcher.trigger 'websocket_rails.subscribe', {channel: @name}
    @callbacks = {}

  bind: (event_name, callback) =>
    @callbacks[event_name] ?= []
    @callbacks[event_name].push callback

  trigger: (event_name, message) =>
    @dispatcher.trigger_channel @name, event_name, message

  dispatch: (event_name, message) =>
    return unless @callbacks[event_name]?
    for callback in @callbacks[event_name]
      callback message

/*
 * The channel object is returned when you subscribe to a channel.
 *
 * For instance:
 *   var dispatcher = new WebSocketRails('localhost:3000/websocket');
 *   var awesome_channel = dispatcher.subscribe('awesome_channel');
 *   awesome_channel.bind('event', function() { console.log('channel event!'); });
 *   awesome_channel.trigger('awesome_event', awesome_object);
 */

WebSocketRails.Channel = function(name,dispatcher) {
  var that = this;
  that.name = name;

  dispatcher.trigger('websocket_rails.subscribe',{channel: name})

  var callbacks = {};

  that.bind = function(event_name, callback) {
    callbacks[event_name] = callbacks[event_name] || [];
    callbacks[event_name].push(callback);
  }

  that.trigger = function(event_name, message) {
    dispatcher.trigger_channel(that.name,event_name,message);
  }

  that.dispatch = function(event_name, message) {
    var chain = callbacks[event_name];
    if (typeof chain == 'undefined') return;
    for(var i = 0; i < chain.length; i++) {
      chain[i]( message );
    }
  }	
}

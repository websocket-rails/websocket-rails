/*
* WebsocketRails JavaScript Client
* 
* Setting up the dispatcher:
* 	var dispatcher = new WebSocketRails('localhost:3000');
* 	dispatcher.on_open = function() {
* 		// trigger a server event immediately after opening connection
* 		dispatcher.trigger('new_user',{user_name: 'guest'});
* 	})
*
* Triggering a new event on the server
* 	dispatcher.trigger('event_name',object_to_be_serialized_to_json);
*
* Listening for new events from the server
* 	dispatcher.bind('event_name', function(data) {
* 		console.log(data.user_name);
* 	})
*/
var WebSocketRails = function(url) {
  var that = this,
      client_id = 0;
  
  that.state = 'connecting';

  if( typeof(WebSocket) != "function" && typeof(WebSocket) != "object" ) {
    var conn = new WebSocketRails.HttpConnection(url);
  } else {
    var conn = new WebSocketRails.WebSocketConnection(url,that);
  }

  var on_open = function(data) {
    that.state = 'connected';
    that.connection_id = data.connection_id;

    if (typeof that.on_open !== 'undefined') {
      that.on_open(data);
    }
  }

  conn.new_message = function(data) {
    for(i = 0; i < data.length; i++) {
      socket_message = data[i];
      var is_channel = false;

      if (socket_message.length > 2) {
        var channel_name = socket_message[0],
            event_name   = socket_message[1],
            message      = socket_message[2];
        is_channel = true;
      } else {
        var event_name = socket_message[0],
            message    = socket_message[1];
      }
      if (that.state === 'connecting' && event_name === 'client_connected') {
        on_open(message);
      }
      if (is_channel == true) {
        that.dispatch_channel(channel_name, event_name, message);
      } else {
        that.dispatch(event_name, message);
      }
    }
  }

  var callbacks = {};

  that.bind = function(event_name, callback) {
    callbacks[event_name] = callbacks[event_name] || [];
    callbacks[event_name].push(callback);
  }

  that.trigger = function(event_name, data) {
    conn.trigger(event_name,data,that.connection_id);
  }

  that.trigger_channel = function(channel, event_name, data) {
    conn.trigger_channel(channel,event_name,data,that.connection_id);
  }

  var channels = {};
  that.subscribe = function(channel_name) {
    var channel = new WebSocketRails.Channel(channel_name,this);
    channels[channel_name] = channel;
    return channel;
  }
  
  that.dispatch = function(event_name, message) {
    var chain = callbacks[event_name];
    if (typeof chain == 'undefined') return;
    for(var i = 0; i < chain.length; i++) {
      chain[i]( message );
    }
  }	

  that.dispatch_channel = function(channel, event_name, message) {
    var channel = channels[channel];
    if (typeof channel == 'undefined') return;
    channel.dispatch(event_name, message);
  }
}

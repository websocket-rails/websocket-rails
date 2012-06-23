/*
* WebsocketRails JavaScript Client
* 
* Setting up the dispatcher:
* 	var dispatcher = new WebSocketRails('localhost:3000');
* 	dispatcher.onopen(function() {
* 		// trigger a server event immediately after opening connection
* 		dispatcher.trigger('new_user',{user_name: 'guest'})
* 	})
*
* Triggering a new event on the server
* 	dispatcher.trigger('event_name',object_to_be_serialized_to_json)
*
* Listening for new events from the server
* 	dispatcher.bind('event_name', function(data) {
* 		alert(data.user_name)
* 	})
*/
var WebSocketRails = function(url) {
  var that = this,
      client_id = 0;
  
  that.state = 'connecting';

  //var conn = new WebSocketRails.HttpConnection(url);
  var conn = new WebSocketRails.WebSocketConnection(url);

  var on_open = function(data) {
    that.state = 'connected';
    that.connection_id = data.connection_id;

    if (typeof that.on_open !== 'undefined') {
      that.on_open(data);
    }
  }

  conn.new_message = function(data) {
    if (data.length > 2) {
      var channel_name = data[0],
          event_name   = data[1],
          message      = data[2];
    } else {
      var event_name = data[0],
          message    = data[1];
    }
    if (that.state === 'connecting' && event_name === 'client_connected') {
      on_open(message);
    }
    that.dispatch(event_name, message);
  }

  var callbacks = {};

  that.bind = function(event_name, callback) {
    callbacks[event_name] = callbacks[event_name] || [];
    callbacks[event_name].push(callback);
  }

  that.trigger = function(event_name, callback) {
    conn.trigger(event_name,callback,that.connection_id);
  }

  
  that.dispatch = function(event_name, message) {
    var chain = callbacks[event_name];
    if (typeof chain == 'undefined') return;
    for(var i = 0; i < chain.length; i++) {
      chain[i]( message );
    }
  }	
}

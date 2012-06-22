/*
* Example WebSocket event dispatcher.
* 
* Setting up the dispatcher:
* 	var dispatcher = new ServerEventsDispatcher()
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
var ServerEventsDispatcher = function(){
  var conn = new WebSocket("ws://localhost:3000/websocket"),
  	open_handler = function(){},
  	callbacks = {},
  	client_id = '';

	this.bind = function(event_name, callback) {
		callbacks[event_name] = callbacks[event_name] || [];
		callbacks[event_name].push(callback)
	}

	this.trigger = function(event_name, data) {
		var payload = JSON.stringify([event_name,data])
		conn.send( payload )
		return this;
	}

	conn.onopen = function(evt) {
    open_handler()
	}
  this.onopen = function(handler) {
    open_handler = handler
  }

	conn.onmessage = function(evt) {
		var data = JSON.parse(evt.data),
			event_name = data[0],
			message = data[1];
    
    if (client_id === '' && event_name === 'client_connected') {
      client_id = message.connection_id
    }
		console.log(data)
		dispatch(event_name, message)
	}

	conn.onclose = function(evt) {
		dispatch('connection_closed', '')
	}

	var dispatch = function(event_name, message) {
		var chain = callbacks[event_name]
		if (typeof chain == 'undefined') return;
		for(var i = 0; i < chain.length; i++) {
			chain[i]( message )
		}
	}	
}

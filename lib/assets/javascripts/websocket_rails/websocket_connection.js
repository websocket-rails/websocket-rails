/*
 * WebSocket Interface for the WebSocketRails client.
 */
WebSocketRails.WebSocketConnection = function(url){
  var that = this,
  conn = new WebSocket("ws://"+url);

  that.trigger = function(event_name, data, client_id) {
    var payload = JSON.stringify([event_name,data])
    conn.send( payload )
    return this;
  }

  conn.onmessage = function(evt) {
    var data = JSON.parse(evt.data);

    console.log(data)
    that.new_message(data);
  }

  conn.onclose = function(evt) {
    WebSocketRails.dispatch('connection_closed', '')
  }

  var dispatch = function(event_name, message) {
    var chain = callbacks[event_name]
    if (typeof chain == 'undefined') return;
    for(var i = 0; i < chain.length; i++) {
      chain[i]( message )
    }
  }	
}

/*
* HTTP Interface for the WebSocketRails client.
*/
WebSocketRails.HttpConnection = function(url){
  var that = this,
      conn = new XMLHttpRequest(),
      lastPos = 0;

  conn.onreadystatechange = function() {
    if (conn.readyState == 3) {
      var data = conn.responseText.substring(lastPos);
      lastPos = conn.responseText.length;
      var json_data = JSON.parse(data);

      console.log(json_data);
      that.new_message(json_data);
    }
  }
  conn.open("GET","/websocket",true);
  conn.send();


  that.trigger = function(event_name, data, client_id) {
    var payload = JSON.stringify([event_name,data]);
    $.ajax({
        type: 'POST',
        url: '/websocket',
        data: {client_id: client_id, data: payload},
        success: function(){console.log('success');}
    });
    return this;
  }

}

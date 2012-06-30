/*
 * HTTP Interface for the WebSocketRails client.
 */
WebSocketRails.HttpConnection = function(url,dispatcher){
  var that = this,
      conn = WebSocketRails.createXMLHttpObject(),
      lastPos = 0;

  conn.onreadystatechange = function() {
    if (conn.readyState == 3) {
      var data = conn.responseText.substring(lastPos);
      lastPos = conn.responseText.length;

      console.log('raw data: '+data);
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

  that.trigger_channel = function(channel, event_name, data, client_id) {
    var payload = JSON.stringify([channel,event_name,data]);
    $.ajax({
      type: 'POST',
      url: '/websocket',
      data: {client_id: client_id, data: payload},
      success: function(){console.log('success');}
    });
    return this;
  }
}

WebSocketRails.XMLHttpFactories = [
  function () {return new XMLHttpRequest()},
  function () {return new ActiveXObject("Msxml2.XMLHTTP")},
  function () {return new ActiveXObject("Msxml3.XMLHTTP")},
  function () {return new ActiveXObject("Microsoft.XMLHTTP")}
];

WebSocketRails.createXMLHttpObject = function() {
  var xmlhttp = false,
      factories = WebSocketRails.XMLHttpFactories;
  for (var i=0;i<factories.length;i++) {
    try {
      xmlhttp = factories[i]();
    }
    catch (e) {
      continue;
    }
    break;
  }
  return xmlhttp;
}

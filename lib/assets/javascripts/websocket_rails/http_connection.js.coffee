###
 HTTP Interface for the WebSocketRails client.
###
class WebSocketRails.HttpConnection
  httpFactories: -> [
    -> new XMLHttpRequest(),
    -> new ActiveXObject("Msxml2.XMLHTTP"),
    -> new ActiveXObject("Msxml3.XMLHTTP"),
    -> new ActiveXObject("Microsoft.XMLHTTP")
  ]

  createXMLHttpObject: =>
    xmlhttp   = false
    factories = @httpFactories()
    for factory in factories
      try
        xmlhttp = factory()
      catch e
        continue
      break
    xmlhttp

  constructor: (@url, @dispatcher) ->
    @_conn    = @createXMLHttpObject()
    @last_pos = 0
    @_conn.onreadystatechange = @parse_stream
    @_conn.open "GET", "/websocket", true
    @_conn.send()

  parse_stream: =>
    if @_conn.readyState == 3
      data         = @_conn.responseText.substring @last_pos
      @last_pos    = @_conn.responseText.length
      decoded_data = JSON.parse data
      @dispatcher.new_message decoded_data

  trigger: (event) =>
    @post_data event.connection_id, event.serialize()

  trigger_channel: (channel_name, event_name, data, connection_id) =>
    payload = JSON.stringify [channel_name, event_name, data]
    @post_data connection_id, payload

  post_data: (connection_id, payload) ->
    $.ajax "/websocket",
      type: 'POST'
      data:
        client_id: connection_id
        data: payload
      success: ->
        console.log "success"

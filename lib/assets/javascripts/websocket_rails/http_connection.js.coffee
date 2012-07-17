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
    @_conn         = @createXMLHttpObject()
    @last_pos      = 0
    @message_queue = []
    @_conn.onreadystatechange = @parse_stream
    @_conn.open "GET", "/websocket", true
    @_conn.send()

  parse_stream: =>
    if @_conn.readyState == 3
      data         = @_conn.responseText.substring @last_pos
      @last_pos    = @_conn.responseText.length
      data = data.replace "]][[", "],["
      console.log data
      decoded_data = JSON.parse data
      @dispatcher.new_message decoded_data

  trigger: (event) =>
    if @dispatcher.state != 'connected'
      @message_queue.push event
    else
      @post_data @dispatcher.connection_id, event.serialize()

  post_data: (connection_id, payload) ->
    $.ajax "/websocket",
      type: 'POST'
      data:
        client_id: connection_id
        data: payload
      success: ->
        console.log "success"

  flush_queue: (connection_id) =>
    for event in @message_queue
      # Events queued before connecting do not have the correct
      # connection_id set yet. We need to update it before dispatching.
      if connection_id?
        event.connection_id = connection_id
      @trigger event
    @message_queue = []

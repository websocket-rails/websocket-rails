###
WebSocket Interface for the WebSocketRails client.
###
class WebSocketRails.WebSocketConnection extends WebSocketRails.AbstractConnection
  connection_type: 'websocket'
  
  constructor: (@url, @dispatcher) ->
    super
    if @url.match(/^wss?:\/\//)
        console.log "WARNING: Using connection urls with protocol specified is depricated"
    else if window.location.protocol == 'https:'
        @url             = "wss://#{@url}"
    else
        @url             = "ws://#{@url}"
    @_conn           = new WebSocket(@url)
    @_conn.onmessage = (event) => 
      event_data = JSON.parse event.data
      @on_message(event_data)
    @_conn.onclose   = (event) => 
      @on_close(event)
    @_conn.onerror   = (event) => 
      @on_error(event)

  close: ->
    @_conn.close()

  send_event: (event) ->
    super
    @_conn.send event.serialize()

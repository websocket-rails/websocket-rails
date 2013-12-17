###
WebSocket Interface for the WebSocketRails client.
###
class WebSocketRails.Connection

  constructor: (@url, @dispatcher) ->
    @message_queue = []
    @state = 'connecting'
    @connection_id


    if @url.match(/^wss?:\/\//)
      console.log "WARNING: Using connection urls with protocol specified is depricated"
    else if window.location.protocol == 'https:'
      @url = "wss://#{@url}"
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

  on_message: (event) ->
    @dispatcher.new_message event

  on_close: (event) ->
    @dispatcher.state = 'disconnected'
    @dispatcher.dispatch new WebSocketRails.Event(['connection_closed', event])

  on_error: (event) ->
    @dispatcher.state = 'disconnected'
    @dispatcher.dispatch new WebSocketRails.Event(['connection_error', event])

  trigger: (event) ->
    if @dispatcher.state != 'connected'
      @message_queue.push event
    else
      @send_event event

  close: ->
    @_conn.close()

  setConnectionId: (connection_id) ->
    @connection_id = connection_id

  send_event: (event) ->
    @_conn.send event.serialize()

  flush_queue: ->
    for event in @message_queue
      @trigger event
    @message_queue = []

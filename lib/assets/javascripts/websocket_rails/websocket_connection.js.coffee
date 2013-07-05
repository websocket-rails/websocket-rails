###
WebSocket Interface for the WebSocketRails client.
###
class WebSocketRails.WebSocketConnection

  constructor: (@url,@dispatcher) ->
    @url             = "ws://#{@url}" unless @url.match(/^wss?:\/\//)
    @message_queue   = []
    @_conn           = new WebSocket(@url)
    @_conn.onmessage = @on_message
    @_conn.onclose   = @on_close
    @_conn.onerror   = @on_error

  trigger: (event) =>
    if @dispatcher.state != 'connected'
      @message_queue.push event
    else
      @_conn.send event.serialize()

  on_message: (event) =>
    data = JSON.parse event.data
    @dispatcher.new_message data

  on_close: (event) =>
    close_event = new WebSocketRails.Event(['connection_closed', event])
    @dispatcher.dispatch close_event

  on_error: (event) =>
    error_event = new WebSocketRails.Event(['connection_error', event])
    @dispatcher.dispatch error_event

  flush_queue: =>
    for event in @message_queue
      @_conn.send event.serialize()
    @message_queue = []

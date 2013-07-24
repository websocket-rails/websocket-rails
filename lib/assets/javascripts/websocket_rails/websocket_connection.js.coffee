###
WebSocket Interface for the WebSocketRails client.
###
class WebSocketRails.WebSocketConnection

  constructor: (@url,@dispatcher) ->
    if @url.match(/^ws?:\/\//) or @url.match(/^wss?:\/\//)
        #URL scheme already defined, nothing to do
    else if window.location.protocol == 'http:'
        @url             = "ws://#{@url}"
    else
        @url             = "wss://#{@url}"
    
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
    @dispatcher.state = 'disconnected'
    @dispatcher.dispatch close_event

  on_error: (event) =>
    error_event = new WebSocketRails.Event(['connection_error', event])
    @dispatcher.state = 'disconnected'
    @dispatcher.dispatch error_event

  flush_queue: =>
    for event in @message_queue
      @_conn.send event.serialize()
    @message_queue = []

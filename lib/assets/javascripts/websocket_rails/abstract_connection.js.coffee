###
 Abstract Interface for the WebSocketRails client.
###
class WebSocketRails.AbstractConnection

  constructor: (url, @dispatcher) ->
    @message_queue   = []

  close: ->

  trigger: (event) ->
    if @dispatcher.state != 'connected'
      @message_queue.push event
    else
      @send_event event

  send_event: (event) ->
    # Events queued before connecting do not have the correct
    # connection_id set yet. We need to update it before dispatching.
    event.connection_id = @connection_id if @connection_id?

    # ...
    
  on_close: (event) ->
    if @dispatcher && @dispatcher._conn == @
      close_event = new WebSocketRails.Event(['connection_closed', event])
      @dispatcher.state = 'disconnected'
      @dispatcher.dispatch close_event

  on_error: (event) ->
    if @dispatcher && @dispatcher._conn == @
      error_event = new WebSocketRails.Event(['connection_error', event])
      @dispatcher.state = 'disconnected'
      @dispatcher.dispatch error_event

  on_message: (event_data) ->
    if @dispatcher && @dispatcher._conn == @
      @dispatcher.new_message event_data

  setConnectionId: (@connection_id) ->

  flush_queue: ->
    for event in @message_queue
      @trigger event
    @message_queue = []

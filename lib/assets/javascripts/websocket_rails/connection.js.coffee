###
WebSocket Interface for the WebSocketRails client.
###
class WebSocketRails.Connection

  constructor: (@url, @dispatcher) ->
    @message_queue = []
    @state = 'connecting'
    @connection_id


    unless @url.match(/^wss?:\/\//) || @url.match(/^ws?:\/\//)
      if window.location.protocol == 'https:'
        @url = "wss://#{@url}"
      else
        @url = "ws://#{@url}"

    @_conn = new WebSocket(@url)

    @_conn.onmessage = (event) =>
      event_data = JSON.parse event.data
      @on_message(event_data)

    @_conn.onclose = (event) =>
      @on_close(event)

    @_conn.onerror = (event) =>
      @on_error(event)

  on_message: (event) ->
    @dispatcher.new_message event

  on_close: (event) ->
    @dispatcher.state = 'disconnected'
    # Pass event.data here if this was triggered by the WebSocket directly
    data = if event?.data then event.data else event
    @dispatcher.dispatch new WebSocketRails.Event(['connection_closed', data])

  on_error: (event) ->
    @dispatcher.state = 'disconnected'
    # Pass event.data here since this was triggered by the WebSocket directly
    @dispatcher.dispatch new WebSocketRails.Event(['connection_error', event.data])

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

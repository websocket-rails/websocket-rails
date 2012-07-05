###
WebSocket Interface for the WebSocketRails client.
###
class WebSocketRails.WebSocketConnection

  constructor: (@url,@dispatcher) ->
    @url             = "ws://#{@url}" unless @url.match(/^wss?:\/\//)
    @_conn           = new WebSocket(@url)
    @_conn.onmessage = @on_message
    @_conn.onclose   = @on_close

  trigger: (event_name, data, connection_id) =>
    payload = JSON.stringify [event_name, data]
    @_conn.send payload

  trigger_channel: (channel_name, event_name, data, connection_id) =>
    payload = JSON.stringify [channel_name, event_name, data]
    @_conn.send payload

  on_message: (event) =>
    data = JSON.parse event.data
    console.log data
    @dispatcher.new_message data

  on_close: (event) =>
    @dispatcher.dispatch 'connection_closed', {}

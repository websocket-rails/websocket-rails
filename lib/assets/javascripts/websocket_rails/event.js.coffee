###
The Event object stores all the relevant event information.
###

class WebSocketRails.Event

  constructor: (data, @success_callback, @failure_callback) ->
    @name    = data[0]
    attr     = data[1]
    if attr?
      @id      = if attr['id']? then attr['id'] else (((1+Math.random())*0x10000)|0)
      @channel = if attr.channel? then attr.channel
      @data    = if attr.data? then attr.data else attr
      @token   = if attr.token? then attr.token
      @connection_id = data[2]
      if attr.success?
        @result  = true
        @success = attr.success

  is_channel: ->
    @channel?

  is_result: ->
    typeof @result != 'undefined'

  is_ping: ->
    @name == 'websocket_rails.ping'

  serialize: ->
      JSON.stringify [@name, @attributes()]

  attributes: ->
    id: @id,
    channel: @channel,
    data: @data
    token: @token

  run_callbacks: (@success, @result) ->
    if @success == true
      @success_callback?(@result)
    else
      @failure_callback?(@result)

###
The Event object stores all the relevant event information.
###

class WebSocketRails.Event

  constructor: (message, @success_callback, @failure_callback) ->
    @name    = message[0]
    options     = message[2]
    if options?
      @id      = if options['id']? then options['id'] else (((1+Math.random())*0x10000)|0)
      @channel = if options.channel? then options.channel
      @data = message[1]
      @token   = if options.token? then options.token
      @connection_id = options.connection_id
      if options.success?
        @result  = true
        @success = options.success

  is_channel: ->
    @channel?

  is_result: ->
    typeof @result != 'undefined'

  is_ping: ->
    @name == 'websocket_rails.ping'

  serialize: ->
    JSON.stringify [@name, @data, @meta_data()]

  meta_data: ->
    id: @id,
    connection_id: @connection_id,
    channel: @channel,
    token: @token

  run_callbacks: (@success, @result) ->
    if @success == true
      @success_callback?(@result)
    else
      @failure_callback?(@result)

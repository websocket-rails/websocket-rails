###
The Event object stores all the relevant event information.
###

class WebSocketRails.Event

  constructor: (options, @successCallback, @failureCallback) ->
    @name = options[0]
    attr = options[1]
    @connection_id = options[2]

    if attr?
      @id       = if attr['id']? then attr['id'] else (((1+Math.random())*0x10000)|0)
      @data     = if attr.data? then attr.data else attr
      @channel  = attr.channel

      if attr.success?
        @result  = true
        @success = attr.success

  isChannel: =>
    @channel?

  isFileUpload: =>
    false

  isResult: =>
    @result == true

  isPing: =>
    @name == 'websocket_rails.ping'

  serialize: =>
      JSON.stringify [@name, @attributes()]

  attributes: =>
    id: @id,
    channel: @channel,
    data: @data,

  run_callbacks: (success, data) =>
    if success == true
      @successCallback?(data)
    else
      @failureCallback?(data)

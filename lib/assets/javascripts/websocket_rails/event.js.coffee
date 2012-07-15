###
The Event object stores all the relevant event information.
###

class WebSocketRails.Event

  constructor: (data,success_callback,failure_callback) ->
    @name    = data[0]
    attr     = data[1]
    @id      = if attr['id']? then attr['id'] else (((1+Math.random())*0x10000)|0)
    @channel = if attr.channel? then attr.channel
    @data    = if attr.data? then attr.data else attr
    @connection_id = data[2]
    @success_callback = success_callback
    @failure_callback = failure_callback
    if attr.success?
      @result  = true
      @success = attr.success

  is_channel: =>
    @channel?

  is_result: =>
    @result == true

  serialize: =>
      JSON.stringify [@name, @attributes()]

  attributes: =>
    id: @id
    channel: @channel
    data: @data

  run_callbacks: (success,data) =>
    if success == true
      @success_callback?(data)
    else
      @failure_callback?(data)

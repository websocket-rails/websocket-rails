###
The Event object stores all the relevant event information.
###

class WebSocketRails.Event

  constructor: (data) ->
    @name    = data[0]
    attr     = data[1]
    @id      = (((1+Math.random())*0x10000)|0) unless attr['id']?
    @channel = if attr.channel? then attr.channel
    @data    = if attr.data? then attr.data else ""
    @connection_id = data[2]

  is_channel: =>
    @channel?

  serialize: =>
      JSON.stringify [@name, @attributes()]

  attributes: =>
    id: @id
    channel: @channel
    data: @data

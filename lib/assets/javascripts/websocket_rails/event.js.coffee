###
The Event object stores all the releavant information for events
that are being queued for sending to the server.
###

class WebSocketRails.Event

  constructor: (data) ->
    @id      = (((1+Math.random())*0x10000)|0)
    @channel = data.shift() if data.length > 2
    @name    = data[0]
    @data    = data[1]

  is_channel: =>
    @channel?

  serialize: =>
    if @is_channel()
      JSON.stringify [@id, @channel, @name, @data]
    else
      JSON.stringify [@id, @name, @data]




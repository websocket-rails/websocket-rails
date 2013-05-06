class WebSocketRails.UploadEvent extends WebSocketRails.Event

  constructor: (eventName, @file, data, connectionId, @successCallback, @failureCallback, @_conn) ->
    super([eventName, data, connectionId], @successCallback, @failureCallback)

    @fileReader = new FileReader
    @fileReader.onloadend = @storeBinaryData
    @fileReader.readAsArrayBuffer(@file)

  isFileUpload: ->
    true

  attributes: =>
    id: @id
    channel: @channel
    data: @data
    upload_event: true
    raw_file_data:
      filename: @file.name
      file_size: @file.size
      type: @file.type
      array_buffer: @bufferView

  storeBinaryData: (event) =>
    @arrayBuffer = event.target.result
    @bufferView = new Uint8Array(@arrayBuffer)

    window.buffer = @bufferView
    console.log @arrayBuffer
    # Since FileReader.readAsBinaryString runs asynchronously, we
    # need to wait to trigger this event until the binary data is
    # ready. The triggerCallback function is set by the dispatcher.
    @_conn.trigger this


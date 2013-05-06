class window.FileReader
  readAsArrayBuffer: (file) =>
    @onloadend {target: {result: 'xyz'}}

describe 'WebSocketRails.UploadEvent', ->

  beforeEach ->
    @file = {name: 'test_file.jpg', size: 4321, type: 'image/jpeg'}
    @conn =
      trigger: (event) ->
        @called = true
    @event = new WebSocketRails.UploadEvent('test_upload', @file, {}, 12345, {}, {}, @conn)

  it 'should call the triggerCallback function after extracting the binary data', ->
    expect(@conn.called).toEqual true

  describe '.isFileUpload()', ->
    it 'should be true', ->
      expect(@event.isFileUpload()).toEqual true

  describe '.attributes()', ->
    it 'should include the raw_file_data', ->
      expect(@event.attributes().raw_file_data.filename).toEqual 'test_file.jpg'
      expect(@event.attributes().raw_file_data.file_size).toEqual 4321
      expect(@event.attributes().raw_file_data.type).toEqual 'image/jpeg'
      expect(@event.attributes().raw_file_data.array_buffer).toEqual 'xyz'

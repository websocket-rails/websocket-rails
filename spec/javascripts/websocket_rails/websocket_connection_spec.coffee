describe 'WebsocketRails.WebSocketConnection:', ->
  beforeEach ->
    dispatcher =
      new_message: -> true
      dispatch: -> true
    WebSocket = (url) ->
      @url  = url
      @send = ->
    @connection = new WebSocketRails.WebSocketConnection('localhost:3000/websocket',dispatcher)

  describe 'constructor', ->
    
    it 'should set the onmessage event on the WebSocket object to this.on_message', ->
      expect(@connection._conn.onmessage).toEqual @connection.on_message

    it 'should set the onclose event on the WebSocket object to this.on_close', ->
      expect(@connection._conn.onclose).toEqual @connection.on_close

    describe 'with ssl', ->
      it 'should not add the ws:// prefix to the URL', ->
        connection = new WebSocketRails.WebSocketConnection('wss://localhost.com')
        expect(connection.url).toEqual 'wss://localhost.com'

    describe 'without ssl', ->
      it 'should add the ws:// prefix to the URL', ->
        expect(@connection.url).toEqual 'ws://localhost:3000/websocket'

  describe '.trigger', ->

    it 'should encode the data and send it through the WebSocket object', ->
      message = ['event','message']
      mock_connection = sinon.mock @connection._conn
      mock_connection.expects('send').once().withArgs JSON.stringify(message)
      @connection.trigger 'event', 'message', 123
      mock_connection.verify()

  describe '.trigger_channel', ->

    it 'should encode the data and send it through the WebSocket object', ->
      message = ['channel','event','message']
      mock_connection = sinon.mock @connection._conn
      mock_connection.expects('send').once().withArgs JSON.stringify(message)
      @connection.trigger_channel 'channel', 'event', 'message', 123
      mock_connection.verify()

  describe '.on_message', ->

    it 'should decode the message and pass it to the dispatcher', ->
      encoded_data = JSON.stringify ['event','message']
      event =
        data: encoded_data
      mock_dispatcher = sinon.mock @connection.dispatcher
      mock_dispatcher.expects('new_message').once().withArgs JSON.parse encoded_data
      @connection.on_message event
      mock_dispatcher.verify()

  describe '.on_close', ->

    it 'should dispatch the connection_closed event', ->
      mock_dispatcher = sinon.mock @connection.dispatcher
      mock_dispatcher.expects('dispatch').withArgs 'connection_closed', {}
      @connection.on_close()
      mock_dispatcher.verify()

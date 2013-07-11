describe 'WebsocketRails.WebSocketConnection:', ->
  beforeEach ->
    dispatcher =
      new_message: -> true
      dispatch: -> true
      state: 'connected'
    # Have to stub the WebSocket object due to Firefox error during jasmine:ci
    window.WebSocket = (url) ->
      @url  = url
      @send = -> true
    @dispatcher = dispatcher
    @connection = new WebSocketRails.WebSocketConnection('localhost:3000/websocket', dispatcher)

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

    describe 'before the connection has been fully established', ->
      it 'should queue up the events', ->
        @connection.dispatcher.state = 'connecting'
        event = new WebSocketRails.Event ['event','message']
        mock_queue = sinon.mock @connection.message_queue
        mock_queue.expects('push').once().withArgs event

    describe 'after the connection has been fully established', ->
      it 'should encode the data and send it through the WebSocket object', ->
        @connection.dispatcher.state = 'connected'
        event = new WebSocketRails.Event ['event','message']
        @connection._conn =
          send: -> true
        mock_connection = sinon.mock @connection._conn
        mock_connection.expects('send').once().withArgs event.serialize()
        @connection.trigger event
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
    it 'should dispatch the connection_closed event and pass the original event', ->
      event = new WebSocketRails.Event ['event','message']
      close_event = new WebSocketRails.Event(['connection_closed', event ])
      sinon.spy @dispatcher, 'dispatch'
      @connection.on_close close_event

      dispatcher = @dispatcher.dispatch
      lastCall = dispatcher.lastCall.args[0]
      expect(dispatcher.calledOnce).toBe(true)
      expect(lastCall.data).toEqual event.data

      dispatcher.restore()

    it 'sets the connection state on the dispatcher to disconnected', ->
      close_event = new WebSocketRails.Event(['connection_closed', {} ])
      @connection.on_close close_event

      expect(@dispatcher.state).toEqual('disconnected')

  describe '.on_error', ->
    it 'should dispatch the connection_error event and pass the original event', ->

      event = new WebSocketRails.Event ['event','message']
      error_event = new WebSocketRails.Event(['connection_error', event ])
      sinon.spy @dispatcher, 'dispatch'
      @connection.on_error event

      dispatcher = @dispatcher.dispatch
      lastCall = dispatcher.lastCall.args[0]
      expect(dispatcher.calledOnce).toBe(true)
      expect(lastCall.data).toEqual event.data

      dispatcher.restore()

    it 'sets the connection state on the dispatcher to disconnected', ->
      close_event = new WebSocketRails.Event(['connection_closed', {} ])
      @connection.on_error close_event

      expect(@dispatcher.state).toEqual('disconnected')

  describe '.flush_queue', ->
    beforeEach ->
      @event = new WebSocketRails.Event ['event','message']
      @connection.message_queue.push @event
      @connection._conn =
        send: -> true

    it 'should send out all of the messages in the queue', ->
      mock_connection = sinon.mock @connection._conn
      mock_connection.expects('send').once().withArgs @event.serialize()
      @connection.flush_queue()
      mock_connection.verify()

    it 'should empty the queue after sending', ->
      expect( @connection.message_queue.length ).toEqual 1
      @connection.flush_queue()
      expect( @connection.message_queue.length ).toEqual 0


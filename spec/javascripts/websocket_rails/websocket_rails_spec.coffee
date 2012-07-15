describe 'WebSocketRails:', ->
  beforeEach ->
    @url = 'localhost:3000/websocket'
    WebSocketRails.WebSocketConnection = ->
      connection_type: 'websocket'
      flush_queue: -> true
    WebSocketRails.HttpConnection = ->
      connection_type: 'http'
      flush_queue: -> true
    @dispatcher = new WebSocketRails @url

  describe 'constructor', ->

    it 'should set the new_message method on connection to this.new_message', ->
      expect(@dispatcher._conn.new_message).toEqual @dispatcher.new_message

    it 'should set the initial state to connecting', ->
      expect(@dispatcher.state).toEqual 'connecting'

    describe 'when use_websockets is true', ->
      it 'should use the WebSocket Connection', ->
        dispatcher = new WebSocketRails @url, true
        expect(dispatcher._conn.connection_type).toEqual 'websocket'

    describe 'when use_webosckets is false', ->
      it 'should use the Http Connection', ->
        dispatcher = new WebSocketRails @url, false
        expect(dispatcher._conn.connection_type).toEqual 'http'

    describe 'when the browser does not support WebSockets', ->
      it 'should use the Http Connection', ->
        window.WebSocket = 'undefined'
        dispatcher = new WebSocketRails @url, true
        expect(dispatcher._conn.connection_type).toEqual 'http'

  describe '.new_message', ->

    describe 'when this.state is "connecting"', ->
      beforeEach ->
        @message =
          data:
            connection_id: 123
        @data = [['client_connected', @message]]

      it 'should call this.connection_established on the "client_connected" event', ->
        mock_dispatcher = sinon.mock @dispatcher
        mock_dispatcher.expects('connection_established').once().withArgs @message.data
        @dispatcher.new_message @data
        mock_dispatcher.verify()

      it 'should set the state to connected', ->
        @dispatcher.new_message @data
        expect(@dispatcher.state).toEqual 'connected'

      it 'should flush any messages queued before the connection was established', ->
        mock_con = sinon.mock @dispatcher._conn
        mock_con.expects('flush_queue').once()
        @dispatcher.new_message @data
        mock_con.verify()

      it 'should set the correct connection_id', ->
        @dispatcher.new_message @data
        expect(@dispatcher.connection_id).toEqual 123

      it 'should call the user defined on_open callback', ->
        spy = sinon.spy()
        @dispatcher.on_open = spy
        @dispatcher.new_message @data
        expect(spy.calledOnce).toEqual true

    describe 'after the connection has been established', ->
      beforeEach ->
        @dispatcher.state = 'connected'
        @attributes =
          data: 'message'
          channel: 'channel'

      it 'should dispatch channel messages', ->
        data = [['event',@attributes]]
        mock_dispatcher = sinon.mock @dispatcher
        mock_dispatcher.expects('dispatch_channel').once()
        @dispatcher.new_message data
        mock_dispatcher.verify()

      it 'should dispatch standard events', ->
        data = [['event','message']]
        mock_dispatcher = sinon.mock @dispatcher
        mock_dispatcher.expects('dispatch').once()
        @dispatcher.new_message data
        mock_dispatcher.verify()

  describe '.bind', ->

    it 'should store the callback on the correct event', ->
      callback = ->
      @dispatcher.bind 'event', callback
      expect(@dispatcher.callbacks['event']).toContain callback

  describe '.dispatch', ->

    it 'should execute the callback for the correct event', ->
      callback = sinon.spy()
      event = new WebSocketRails.Event(['event',{data: 'message'}])
      @dispatcher.bind 'event', callback
      @dispatcher.dispatch event
      expect(callback.calledWith('message')).toEqual true

  describe 'triggering events with', ->
    beforeEach ->
      @dispatcher.connection_id = 123
      @dispatcher._conn =
        trigger: ->
        trigger_channel: ->

    describe '.trigger', ->

      it 'should delegate to the connection object', ->
        con_trigger = sinon.spy @dispatcher._conn, 'trigger'
        @dispatcher.trigger 'event', 'message'
        event = new WebSocketRails.Event ['websocket_rails.subscribe', {channel: 'awesome'}, 123]
        expect(con_trigger.called).toEqual true

    describe '.trigger_channel', ->

      it 'should delegate to the Connection object', ->
        con_trigger_channel = sinon.spy @dispatcher._conn, 'trigger_channel'
        @dispatcher.trigger_channel 'channel', 'event', 'message'
        expect(con_trigger_channel.calledWith('channel','event','message',123)).toEqual true

  describe 'working with channels', ->
    beforeEach ->
      WebSocketRails.Channel = ->

    describe '.subscribe', ->
      describe 'for new channels', ->
        it 'should create and store a new Channel object', ->
          channel = @dispatcher.subscribe 'test_channel'
          channel.name = 'test'
          expect(@dispatcher.channels['test_channel']).toEqual channel

      describe 'for existing channels', ->
        it 'should return the same Channel object', ->
          channel = @dispatcher.subscribe 'test_channel'
          channel.name = 'test'
          expect(@dispatcher.subscribe('test_channel')).toEqual channel

    describe '.dispatch_channel', ->

      it 'should delegate to the Channel object', ->
        channel = @dispatcher.subscribe 'test'
        channel.dispatch = ->
        spy = sinon.spy channel, 'dispatch'
        event = new WebSocketRails.Event(['event',{channel: 'test', data: 'awesome'}])
        @dispatcher.dispatch_channel event
        expect(spy.calledWith('event', 'awesome')).toEqual true


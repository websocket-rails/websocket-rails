describe 'WebSocketRails:', ->
  beforeEach ->
    @url = 'localhost:3000/websocket'
    WebSocketRails.WebSocketConnection = class WebSocketConnectionStub extends WebSocketRails.AbstractConnection
      connection_type: 'websocket'
    WebSocketRails.HttpConnection = class HttpConnectionStub extends WebSocketRails.AbstractConnection
      connection_type: 'http'
    @dispatcher = new WebSocketRails @url

  describe 'constructor', ->
    it 'should start connection automatically', ->
      expect(@dispatcher.state).toEqual 'connecting'

  describe '.connect', ->

    it 'should set the new_message method on connection to this.new_message', ->
      expect(@dispatcher._conn.new_message).toEqual @dispatcher.new_message

    it 'should set the initial state to connecting', ->
      expect(@dispatcher.state).toEqual 'connecting'

    describe 'when use_websockets is true', ->
      it 'should use the WebSocket Connection', ->
        dispatcher = new WebSocketRails @url, true
        expect(dispatcher._conn.connection_type).toEqual 'websocket'

    describe 'when use_websockets is false', ->
      it 'should use the Http Connection', ->
        dispatcher = new WebSocketRails @url, false
        expect(dispatcher._conn.connection_type).toEqual 'http'

    describe 'when the browser does not support WebSockets', ->
      it 'should use the Http Connection', ->
        window.WebSocket = 'undefined'
        dispatcher = new WebSocketRails @url, true
        expect(dispatcher._conn.connection_type).toEqual 'http'

  describe '.disconnect', ->
    beforeEach ->
      @dispatcher.disconnect()

    it 'should close the connection', ->
      expect(@dispatcher.state).toEqual 'disconnected'

    it 'existing connection should be destroyed', ->
      expect(@dispatcher._conn).toBeUndefined()

  describe '.reconnect', ->
    OLD_CONNECTION_ID = 1
    NEW_CONNECTION_ID = 2

    it 'should connect, when disconnected', ->
      mock_dispatcher = sinon.mock @dispatcher
      mock_dispatcher.expects('connect').once()
      @dispatcher.disconnect()
      @dispatcher.reconnect()
      mock_dispatcher.verify()

    it 'should recreate the connection', ->
      helpers.startConnection(@dispatcher, OLD_CONNECTION_ID)
      @dispatcher.reconnect()
      helpers.startConnection(@dispatcher, NEW_CONNECTION_ID)

      expect(@dispatcher._conn.connection_id).toEqual NEW_CONNECTION_ID

    it 'should resend all uncompleted events', ->
      event = @dispatcher.trigger('create_post')

      helpers.startConnection(@dispatcher, OLD_CONNECTION_ID)
      @dispatcher.reconnect()
      helpers.startConnection(@dispatcher, NEW_CONNECTION_ID)

      expect(@dispatcher.queue[event.id].connection_id).toEqual NEW_CONNECTION_ID

    it 'should not resend completed events', ->
      event = @dispatcher.trigger('create_post')
      event.run_callbacks(true, {})

      helpers.startConnection(@dispatcher, OLD_CONNECTION_ID)
      @dispatcher.reconnect()
      helpers.startConnection(@dispatcher, NEW_CONNECTION_ID)

      expect(@dispatcher.queue[event.id].connection_id).toEqual OLD_CONNECTION_ID

    it 'should reconnect to all channels', ->
      mock_dispatcher = sinon.mock @dispatcher
      mock_dispatcher.expects('reconnect_channels').once()
      @dispatcher.reconnect()
      mock_dispatcher.verify()

  describe '.reconnect_channels', ->
    beforeEach ->
      @channel_callback = -> true
      helpers.startConnection(@dispatcher, 1)
      @dispatcher.subscribe('public 4chan')
      @dispatcher.subscribe_private('private 4chan')
      @dispatcher.channels['public 4chan'].bind('new_post', @channel_callback)

    it 'should recreate existing channels, keeping their private/public type', ->
      @dispatcher.reconnect_channels()
      expect(@dispatcher.channels['public 4chan'].is_private).toEqual false
      expect(@dispatcher.channels['private 4chan'].is_private).toEqual true

    it 'should move all existing callbacks from old channel objects to new ones', ->
      old_public_channel = @dispatcher.channels['public 4chan']

      @dispatcher.reconnect_channels()

      expect(old_public_channel._callbacks).toEqual {}
      expect(@dispatcher.channels['public 4chan']._callbacks).toEqual {new_post: [@channel_callback]}

  describe '.new_message', ->

    describe 'when this.state is "connecting"', ->
      beforeEach ->
        @connection_id = 123

      it 'should call this.connection_established on the "client_connected" event', ->
        mock_dispatcher = sinon.mock @dispatcher
        mock_dispatcher.expects('connection_established').once().withArgs(connection_id: @connection_id)
        helpers.startConnection(@dispatcher, @connection_id)
        mock_dispatcher.verify()

      it 'should set the state to connected', ->
        helpers.startConnection(@dispatcher, @connection_id)
        expect(@dispatcher.state).toEqual 'connected'

      it 'should flush any messages queued before the connection was established', ->
        mock_con = sinon.mock @dispatcher._conn
        mock_con.expects('flush_queue').once()
        helpers.startConnection(@dispatcher, @connection_id)
        mock_con.verify()

      it 'should set the correct connection_id', ->
        helpers.startConnection(@dispatcher, @connection_id)
        expect(@dispatcher._conn.connection_id).toEqual 123

      it 'should call the user defined on_open callback', ->
        spy = sinon.spy()
        @dispatcher.on_open = spy
        helpers.startConnection(@dispatcher, @connection_id)
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

      describe 'result events', ->
        beforeEach ->
          @attributes['success'] = true
          @attributes['id'] = 1
          @event = { run_callbacks: (data) -> }
          @event_mock = sinon.mock @event
          @dispatcher.queue[1] = @event
          @event_data = [['event',@attributes]]

        it 'should run callbacks for result events', ->
          @event_mock.expects('run_callbacks').once()
          @dispatcher.new_message @event_data
          @event_mock.verify()

        it 'should remove the event from the queue', ->
          @dispatcher.new_message @event_data
          expect(@dispatcher.queue[1]).toBeUndefined()


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
      @dispatcher._conn =
        connection_id: 123
        trigger: ->

    describe '.trigger', ->
      it 'should add the event to the queue', ->
        event = @dispatcher.trigger 'event', 'message'
        expect(@dispatcher.queue[event.id]).toEqual event

      it 'should delegate to the connection object', ->
        conn_trigger = sinon.spy @dispatcher._conn, 'trigger'
        @dispatcher.trigger 'event', 'message'
        expect(conn_trigger.called).toEqual true

      it "should not delegate to the connection object, if it's not available", ->
        @dispatcher._conn = null
        @dispatcher.trigger 'event', 'message'

  describe '.connection_stale', ->
    describe 'when state is connected', ->
      it 'should return false', ->
        @dispatcher.state = 'connected'
        expect(@dispatcher.connection_stale()).toEqual false

    describe 'when state is disconnected', ->
      it 'should return true', ->
        @dispatcher.state = 'disconnected'
        expect(@dispatcher.connection_stale()).toEqual true

  describe 'working with channels', ->
    beforeEach ->
      WebSocketRails.Channel = (@name,@dispatcher,@is_private) ->

    describe '.subscribe', ->
      describe 'for new channels', ->
        it 'should create and store a new Channel object', ->
          channel = @dispatcher.subscribe 'test_channel'
          expect(channel.name).toEqual 'test_channel'

      describe 'for existing channels', ->
        it 'should return the same Channel object', ->
          channel = @dispatcher.subscribe 'test_channel'
          expect(@dispatcher.subscribe('test_channel')).toEqual channel

    describe '.subscribe_private', ->
      it 'should create private channels', ->
        private_channel = @dispatcher.subscribe_private 'private_something'
        expect(private_channel.is_private).toBe true

    describe '.unsubscribe', ->
      describe 'for existing channels', ->
        it 'should remove the Channel object', ->
          @dispatcher.unsubscribe 'test_channel'
          expect(@dispatcher.channels['test_channel']).toBeUndefined

    describe '.dispatch_channel', ->

      it 'should delegate to the Channel object', ->
        channel = @dispatcher.subscribe 'test'
        channel.dispatch = ->
        spy = sinon.spy channel, 'dispatch'
        event = new WebSocketRails.Event(['event',{channel: 'test', data: 'awesome'}])
        @dispatcher.dispatch_channel event
        expect(spy.calledWith('event', 'awesome')).toEqual true


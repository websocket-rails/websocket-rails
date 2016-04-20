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
    OLD_CONNECTION_ID = 1
    NEW_CONNECTION_ID = 2
    beforeEach ->
      @channel_callback = -> true
      @dispatcher.subscribe('public 4chan')
      @dispatcher.subscribe_private('private 4chan')
      @dispatcher.channels['public 4chan'][0].bind('new_post', @channel_callback)

    it 'should resubscribe existing channels, keeping their private/public type', ->
      @dispatcher.reconnect_channels()
      expect(@dispatcher.channels['public 4chan'][0].is_private).toEqual false
      expect(@dispatcher.channels['private 4chan'][0].is_private).toEqual true

    it 'should update the connection id of all the channels to the new id', ->
      @dispatcher.disconnect()
      @dispatcher.connect()
      helpers.startConnection(@dispatcher, NEW_CONNECTION_ID)
      @dispatcher.reconnect_channels()
      expect(@dispatcher.channels['public 4chan'][0].connection_id).toEqual NEW_CONNECTION_ID

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

  describe '.unbind', ->

    it 'should delete the callback on the correct event', ->
      callback = ->
      @dispatcher.bind 'event', callback
      @dispatcher.unbind 'event'
      expect(@dispatcher.callbacks['event']).toBeUndefined()

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
    #beforeEach ->
    #  WebSocketRails.Channel = (@name,@dispatcher,@is_private) ->
    describe '.subscribe', ->
      describe 'for new channels', ->
        it 'should create and store a new Channel object', ->
          channel = @dispatcher.subscribe 'test_channel'
          expect(channel.name).toEqual 'test_channel'

      describe 'for existing channels', ->
        beforeEach ->
          sinon.spy @dispatcher, 'trigger_event'
        afterEach ->
          @dispatcher.trigger_event.restore()
        it 'should return a different Channel object', ->
          channel = @dispatcher.subscribe 'test_channel'
          expect(@dispatcher.subscribe('test_channel')).not.toEqual channel
        it "should add a channel to the channel pool", ->
          @dispatcher.subscribe 'test_channel'
          @dispatcher.subscribe 'test_channel'
          expect(@dispatcher.channels["test_channel"].length).toEqual 2
        it 'should resubscribe if channel has been destroyed', ->
          channel = @dispatcher.subscribe 'test_channel'
          expect(@dispatcher.trigger_event.lastCall.args[0].name).toEqual 'websocket_rails.subscribe'
          channel.destroy()
          expect(@dispatcher.trigger_event.lastCall.args[0].name).toEqual 'websocket_rails.unsubscribe'
          channel = @dispatcher.subscribe 'test_channel'
          expect(@dispatcher.trigger_event.lastCall.args[0].name).toEqual 'websocket_rails.subscribe'


    describe '.subscribe_private', ->
      it 'should create private channels', ->
        private_channel = @dispatcher.subscribe_private 'private_something'
        expect(private_channel.is_private).toBe true

    describe '.unsubscribe', ->
      describe 'for existing channels', ->
        it 'should remove all Channel objects with name', ->
          @dispatcher.unsubscribe 'test_channel'
          expect(@dispatcher.channels['test_channel']).toBeUndefined

    describe ".remove_channel", ->
      beforeEach ->
        @channel = @dispatcher.subscribe("test_channel")
        sinon.spy @dispatcher, 'trigger_event'
      afterEach ->
        @dispatcher.trigger_event.restore()
      describe 'with single channel', ->
        it 'should remove channel name from channels', ->
          @dispatcher.remove_channel(@channel)
          expect(@dispatcher.channels['test_channel']).toBeUndefined
        it "should trigger an unsubscribe event", ->
          @dispatcher.remove_channel(@channel)
          expect(@dispatcher.trigger_event.lastCall.args[0].name).toEqual 'websocket_rails.unsubscribe'
      describe 'with multiple channels', ->
        it "should remove channel from channel name list", ->
          new_channel = @dispatcher.subscribe("test_channel")
          @dispatcher.remove_channel(@channel)
          expect(@dispatcher.channels['test_channel'].indexOf @channel).toEqual -1
        it "should leave channel name in channels object", ->
          new_channel = @dispatcher.subscribe("test_channel")
          @dispatcher.remove_channel(@channel)
          expect(@dispatcher.channels['test_channel']).not.toBeUndefined
        it "should not trigger an unsubscribe event", ->
          new_channel = @dispatcher.subscribe("test_channel")
          @dispatcher.remove_channel(@channel)
          expect(@dispatcher.trigger_event.notCalled).toEqual true

    describe '.dispatch_channel', ->

      it 'should delegate to each Channel object', ->
        channel = @dispatcher.subscribe 'test'
        channel2 = @dispatcher.subscribe 'test'
        channel.dispatch = channel2.dispatch = ->
        spy = sinon.spy channel, 'dispatch'
        spy2 = sinon.spy channel2, 'dispatch'
        event = new WebSocketRails.Event(['event',{channel: 'test', data: 'awesome'}])
        @dispatcher.dispatch_channel event
        expect(spy.calledWith('event', 'awesome')).toEqual true
        expect(spy2.calledWith('event', 'awesome')).toEqual true


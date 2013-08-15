describe 'WebSocketRails.Channel:', ->
  beforeEach ->
    @dispatcher =
      new_message: -> true
      dispatch: -> true
      trigger_event: (event) -> true
      state: 'connected'
      connection_id: 12345
    @channel = new WebSocketRails.Channel('public', @dispatcher)
    sinon.spy @dispatcher, 'trigger_event'

  afterEach ->
    @dispatcher.trigger_event.restore()

  describe '.trigger', ->
    describe 'before the channel private token has been set', ->
      it 'queues the events', ->
        @channel._token = undefined
        @channel.trigger 'quickEvent', 'someData'

        event = @channel._eventQueue[0]
        expect(event.name).toEqual 'quickEvent'
        expect(event.data).toEqual 'someData'


  describe 'public channels', ->
    beforeEach ->
      @channel = new WebSocketRails.Channel('forchan', @dispatcher, false)
      @event = @dispatcher.trigger_event.lastCall.args[0]

    it 'should trigger a subscribe event when created', ->
      expect(@event.name).toEqual 'websocket_rails.subscribe'

    it 'should trigger an event containing the channel name', ->
      expect(@event.data.channel).toEqual 'forchan'

    it 'should trigger an event containing the correct connection_id', ->
      expect(@event.connection_id).toEqual 12345

    it 'should initialize an empty callbacks property', ->
      expect(@channel._callbacks).toBeDefined()
      expect(@channel._callbacks).toEqual {}

    it 'should be public', ->
      expect(@channel.is_private).toBeFalsy

    describe '.bind', ->
      it 'should add a function to the callbacks collection', ->
        test_func = ->
        @channel.bind 'event_name', test_func
        expect(@channel._callbacks['event_name'].length).toBe 1
        expect(@channel._callbacks['event_name']).toContain test_func

  describe 'private channels', ->
    beforeEach ->
      @channel = new WebSocketRails.Channel('forchan',@dispatcher,true)
      @event = @dispatcher.trigger_event.lastCall.args[0]

    it 'should trigger a subscribe_private event when created', ->
      expect(@event.name).toEqual 'websocket_rails.subscribe_private'

    it 'should be private', ->
      expect(@channel.is_private).toBe true

describe 'WebSocketRails.Event', ->
  
  describe 'standard events', ->
    beforeEach ->
      @data = ['event', {data: { message: 'test'} }, 12345]
      @event = new WebSocketRails.Event(@data)

    it 'should generate an ID', ->
      expect(@event.id).not.toBeNull

    it 'should have a connection ID', ->
      expect(@event.connection_id).toEqual 12345

    it 'should assign the correct properties when passed a data array', ->
      expect(@event.name).toEqual 'event'
      expect(@event.data.message).toEqual 'test'

    describe '.serialize()', ->
      it 'should serialize the event as JSON', ->
        @event.id = 1
        serialized = "[\"event\",{\"id\":1,\"data\":{\"message\":\"test\"}}]"
        expect(@event.serialize()).toEqual serialized

    describe '.is_channel()', ->
      it 'should be false', ->
        expect(@event.is_channel()).toEqual false

  describe 'channel events', ->
    beforeEach ->
      @data = ['event',{channel:'channel',data:{message: 'test'}}]
      @event = new WebSocketRails.Event(@data)

    it 'should assign the channel property', ->
      expect(@event.channel).toEqual 'channel'
      expect(@event.name).toEqual 'event'
      expect(@event.data.message).toEqual 'test'

    describe '.is_channel()', ->
      it 'should be true', ->
        expect(@event.is_channel()).toEqual true

    describe '.serialize()', ->
      it 'should serialize the event as JSON', ->
        @event.id = 1
        serialized = "[\"event\",{\"id\":1,\"channel\":\"channel\",\"data\":{\"message\":\"test\"}}]"
        expect(@event.serialize()).toEqual serialized

  describe '.run_callbacks()', ->
    beforeEach ->
      success_func = ->
      failure_func = ->
      @data = ['event', {data: { message: 'test'} }, 12345]
      @event = new WebSocketRails.Event(@data, success_func, failure_func)
      spyOn @event, 'success_callback'
      spyOn @event, 'failure_callback'

    describe 'when successful', ->
      beforeEach ->
        @event.run_callbacks 0, 'foo'

      it 'should run the success callback when passed 0', ->
        expect(@event.success_callback).toHaveBeenCalledWith('foo')

      it 'should not run the failure callback when passed 0', ->
        expect(@event.failure_callback).not.toHaveBeenCalled()

    describe 'when failure', ->
      beforeEach ->
        @event.run_callbacks 1, 'foo'

      it 'should run the failure callback when passed 1', ->
        expect(@event.failure_callback).toHaveBeenCalledWith('foo')

      it 'should not run the success callback when passed 1', ->
        expect(@event.success_callback).not.toHaveBeenCalled()

    describe 'when finished without result', ->
      it 'should not run any callbacks when passed 2', ->
        @event.run_callbacks 2, 'foo'
        expect(@event.success_callback).not.toHaveBeenCalled()
        expect(@event.failure_callback).not.toHaveBeenCalled()

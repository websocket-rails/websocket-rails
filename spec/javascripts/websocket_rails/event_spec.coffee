describe 'WebSocketRails.Event', ->
  
  describe 'standard events', ->
    beforeEach ->
      @data = ['event',{data: { message: 'test'} },12345]
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
        expect(@event.serialize()).toMatch /['event',{'message':'test'}]/

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
        expect(@event.serialize()).toMatch /['channel','event',{'message':'test'}]/

module WebsocketRails

  class SpecHelperEvent < Event

    attr_reader :dispatcher, :triggered

    alias :triggered? :triggered

    def initialize(event_name,options={})
      super(event_name, options)
      @triggered = false
      @dispatcher =  Dispatcher.new(nil)
    end

    def trigger
      @triggered = true
    end

    def dispatch
      @dispatcher.dispatch(self)
      self
    end

    def connection
      OpenStruct.new(:id => 1)
    end

  end

end

def create_event(name, data)
  WebsocketRails::SpecHelperEvent.new(name, {data: data})
end

module WebsocketRails
  class EventQueue

    attr_reader :queue

    def initialize(max_workers=1)
      @queue = Queue.new
      @max_workers = max_workers
    end

    def enqueue(event)
      @queue << event
    end
    alias :<< :enqueue

    def last
      @queue.last
    end

    def size
      @queue.size
    end

    def pop
      @workers = @max_workers.times.map do
        Thread.new do
          while (item = @queue.pop) do
            yield item
          end
        end
      end
    end

  end
end

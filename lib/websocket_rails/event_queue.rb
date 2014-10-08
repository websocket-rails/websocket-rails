module WebsocketRails
  class EventQueue

    attr_reader :queue

    def initialize
      @queue = Queue.new
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

    def pop(&block)
      @worker = Thread.new do
        while (item = @queue.pop) do
          block.call item
        end
      end
    end

    def flush(&block)
      unless block.nil?
        @queue.pop do |item|
          block.call item
        end
      end
      @queue = []
    end

  end
end

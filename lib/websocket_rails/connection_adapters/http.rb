module WebsocketRails
  module ConnectionAdapters
    class Http < Base
      TERM = "\r\n".freeze
      TAIL = "0#{TERM}#{TERM}".freeze
      
      def self.accepts?(env)
        true
      end
      
      attr_accessor :headers

      def initialize(env,dispatcher)
        super
        @body = DeferrableBody.new
        @headers = Hash.new
        @headers['Content-Type'] = 'text/json'
        @headers['Transfer-Encoding'] = 'chunked'

        define_deferrable_callbacks
        EM.next_tick { @env['async.callback'].call [200, @headers, @body] }
        on_open
      end

      def send(message)
        @body.chunk encode_chunk( message )
      end
      
      private
      
      def define_deferrable_callbacks
        @body.callback do |event|
          on_close(event)
        end
        @body.errback do |event|
          on_close(event)
        end
      end
      
      # From [Rack::Stream](https://github.com/intridea/rack-stream)
      def encode_chunk(c)
        return nil if c.nil?
        # hack to work with Rack::File for now, should not TE chunked
        # things that aren't strings or respond to bytesize
        c = ::File.read(c.path) if c.kind_of?(Rack::File)
        size = Rack::Utils.bytesize(c)
        return nil if size == 0
        c.dup.force_encoding(Encoding::BINARY) if c.respond_to?(:force_encoding)
        [size.to_s(16), TERM, c, TERM].join
      end
            
      # From [thin_async](https://github.com/macournoyer/thin_async)
      class DeferrableBody
        include EM::Deferrable

        # @param chunks - object that responds to each. holds initial chunks of content
        def initialize(chunks = [])
          @queue = []
          chunks.each {|c| chunk(c)}
        end

        # Enqueue a chunk of content to be flushed to stream at a later time
        def chunk(*chunks)
          @queue += chunks
          schedule_dequeue
        end

        # When rack attempts to iterate over `body`, save the block,
        # and execute at a later time when `@queue` has elements
        def each(&blk)
          @body_callback = blk
          schedule_dequeue
        end

        def empty?
          @queue.empty?
        end

        def close!(flush = true)
          EM.next_tick {
            if !flush || empty?
              succeed
            else
              schedule_dequeue
              close!(flush)
            end
          }
        end

        private

        def schedule_dequeue
          return unless @body_callback
          EM.next_tick do
            next unless c = @queue.shift
            @body_callback.call(c)
            schedule_dequeue unless empty?
          end
        end
      end
      
    end
  end
end

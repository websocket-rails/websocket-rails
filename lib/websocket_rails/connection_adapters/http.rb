module WebsocketRails
  module ConnectionAdapters
    class Http < Base
      TERM = "\r\n".freeze
      TAIL = "0#{TERM}#{TERM}".freeze
      HttpHeaders = {
        'Content-Type'      => 'text/json',
        'Transfer-Encoding' => 'chunked'
      }

      def self.accepts?(env)
        true
      end

      attr_accessor :headers

      def initialize(env,dispatcher)
        super
        @body = DeferrableBody.new
        @headers = HttpHeaders

        define_deferrable_callbacks

        origin = "#{request.protocol}#{request.raw_host_with_port}"
        @headers.merge!({'Access-Control-Allow-Origin' => origin}) if WebsocketRails.config.allowed_origins.include?(origin)
        # IE < 10.0 hack
        # XDomainRequest will not bubble up notifications of download progress in the first 2kb of the response
        # http://blogs.msdn.com/b/ieinternals/archive/2010/04/06/comet-streaming-in-internet-explorer-with-xmlhttprequest-and-xdomainrequest.aspx
        @body.chunk(encode_chunk(" " * 2048))

        EM.next_tick do
          @env['async.callback'].call [200, @headers, @body]
          on_open
        end
      end

      def send(message)
        @body.chunk encode_chunk( message )
      end

      def close!
        @body.close!
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

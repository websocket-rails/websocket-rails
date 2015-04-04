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

      delegate :headers, :close!, :encode_chunk, to: :@connection

      def initialize(request, dispatcher)
        @connection = DeferrableBody.new(request)
        super
      end

      def send(message)
        chunk = encode_chunk(message)
        @connection.write(chunk) unless chunk.nil?
      end

      def on_close(data=nil)
        super data
        @connection.close!
      end

      private

      class DeferrableBody
        def self.ensure_reactor_running
          Thread.new { EventMachine.run } unless EventMachine.reactor_running?
          Thread.pass until EventMachine.reactor_running?
        end

        attr_reader :env, :headers

        def initialize(request, protocols = nil, options = {})
          DeferrableBody.ensure_reactor_running

          @env     = request.env
          @stream  = Faye::RackStream.new(self)
          @headers = HttpHeaders

          origin = "#{request.protocol}#{request.raw_host_with_port}"
          @headers.merge!({'Access-Control-Allow-Origin' => origin}) if WebsocketRails.config.allowed_origins.include?(origin)

          if callback = @env['async.callback']
            callback.call([200, @headers, @stream])
          else
            start   = 'HTTP/1.1 200 OK'
            headers = [start, @headers.map{|k, v| "#{k}: #{v}"}, '', '']
            write(headers.flatten.join("\r\n"))
          end

          # IE < 10.0 hack
          # XDomainRequest will not bubble up notifications of download progress in the first 2kb of the response
          # http://blogs.msdn.com/b/ieinternals/archive/2010/04/06/comet-streaming-in-internet-explorer-with-xmlhttprequest-and-xdomainrequest.aspx
          write encode_chunk(" " * 2048)

          true
        end

        def write(data)
          @stream.write(data)
        end

        def close!
          write(TAIL)
          @stream.close_connection_after_writing
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
      end
    end
  end
end

module WebsocketRails
  module MessageProcessors
    class Registry

      cattr_accessor :processors

      def self.register(processor)
        @@processors ||= []
        @@processors << processor
      end

      attr_reader :dispatcher, :ready_processors

      def initialize(dispatcher)
        @dispatcher = dispatcher
      end

      def processors
        @@processors || []
      end

      def processors_for(message)
        ready_processors.select { |processor| processor.processes?(message) }
      end

      def processes?(message)
        raise NotImplementedError, "Implement in the message specific processor class"
      end

      def init_processors!
        @ready_processors = processors.collect do |processor_class|
          processor = processor_class.new
          processor.dispatcher = dispatcher
          processor.process_inbound
          processor
        end

        self
      end

    end
  end
end

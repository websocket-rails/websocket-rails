require "active_support/concern"

module WebsocketRails
  module Processor

    extend ActiveSupport::Concern

    included do
      MessageProcessors::Registry.register self
      include Logging
    end

    attr_accessor :dispatcher

    delegate :sync, to: Synchronization

    delegate :channel_manager, to: WebsocketRails

    delegate :event_map, to: :dispatcher

    delegate :controller_factory, to: :dispatcher

    delegate :reload_event_map!, to: :dispatcher

    delegate :broadcast_message, to: :dispatcher

    def message_queue
      @message_queue ||= EM::Queue.new
    end

    def process_inbound
      message_queue.pop do |message|
        process_message message

        process_inbound
      end
    end

    def process_message(message)
      raise NotImplementedError
    end

  end
end

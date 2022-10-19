module EventPeople
  module Broker
    class Rabbit::RabbitContext < EventPeople::Broker::Context
      def initialize(channel, delivery_info)
        @channel = channel
        @delivery_info = delivery_info
      end

      def success!
        @channel.ack(@delivery_info.delivery_tag, false)
      end

      def fail!
        @channel.nack(@delivery_info.delivery_tag, false, true)
      end

      def reject!
        @channel.reject(@delivery_info.delivery_tag, false)
      end
    end
  end
end
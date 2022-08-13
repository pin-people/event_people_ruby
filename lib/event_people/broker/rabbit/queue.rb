module EventPeople
  module Broker
    class Rabbit::Queue
      def initialize(channel)
        @channel = channel
        @channel.prefetch(1)
      end

      def self.subscribe(channel, routing_key, &block)
        new(channel).subscribe(routing_key, &block)
      end

      def subscribe(routing_key, &block)
        base_name = routing_key.split('.')[0..2].join('.')
        name = queue_name("#{base_name}.all")

        channel.queue(name, queue_options)
               .bind(topic, routing_key: routing_key)
               .subscribe(manual_ack: true) do |delivery_info, properties, payload|
                 callback(delivery_info, properties, payload, &block)
               end
      end

      private

      attr_reader :channel

      def callback(delivery_info, properties, payload, &block)
        event_name = delivery_info.routing_key

        event = EventPeople::Event.new(event_name, payload)

        block.call(event, channel, delivery_info)
      end

      def topic
        Rabbit::Topic.topic(channel)
      end

      def queue_options
        { durable: true }
      end

      def queue_name(routing_key)
        "#{EventPeople::Config::APP_NAME.downcase}-#{routing_key.downcase}"
      end
    end
  end
end

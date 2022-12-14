module EventPeople
  module Broker
    class Rabbit::Topic
      def initialize(channel)
        @channel = channel
      end

      def self.topic(channel)
        new(channel).topic
      end

      def topic
        @topic ||= channel.topic(EventPeople::Config::TOPIC, topic_options)
      end

      def self.produce(channel, event)
        new(channel).produce(event)
      end

      def produce(event)
        topic.publish(event.payload, routing_key: event.name,
                      content_type: 'application/json')
      end

      private

      attr_reader :channel

      def topic_options
        { passive: true }
      end
    end
  end
end

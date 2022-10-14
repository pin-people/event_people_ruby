module EventPeople
  module Broker
    class Rabbit < Base
      def connection
        @@connection ||= session
      end

      def consume(event_name, &block)
        Queue.subscribe(channel, event_name, &block)
      end

      def produce(events)
        events.each do |event|
          Topic.produce(channel, event)
        end
      end

      def self.close_connection
        @@connection.close
      end

      private

      def channel
        @@channel ||= connection.create_channel
        @@channel = connection.create_channel if @@channel.closed?
        @@channel
      end

      def session
        Bunny.new(url).tap(&:start)
      end

      def url
        EventPeople::Config::FULL_URL
      end
    end
  end
end

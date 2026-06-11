module EventPeople
  module Broker
    class Rabbit::Queue
      def initialize(channel)
        @channel = channel
        @channel.prefetch(1)
      end

      def self.subscribe(channel, routing_key, retry_config: {}, &block)
        new(channel).subscribe(routing_key, retry_config: retry_config, &block)
      end

      def subscribe(routing_key, retry_config: {}, &block)
        base_name = routing_key.split('.')[0..2].join('.')
        name = queue_name("#{base_name}.all")

        declare_dlx_and_dlq
        declare_retry_queue(name)

        channel.queue(name, main_queue_options)
               .bind(topic, routing_key: routing_key)
               .subscribe(manual_ack: true) do |delivery_info, properties, payload|
                 callback(delivery_info, properties, payload, name, retry_config, &block)
               end
      end

      private

      attr_reader :channel

      def declare_dlx_and_dlq
        dlx_name = "#{EventPeople::Config::APP_NAME}_dlx"
        dlq_name = "#{EventPeople::Config::APP_NAME}_dlq"

        dlx = channel.fanout(dlx_name, durable: true)
        channel.queue(dlq_name, durable: true).bind(dlx, routing_key: '')
      end

      def declare_retry_queue(main_queue_name)
        channel.queue("#{main_queue_name}_retry", durable: true, arguments: {
          'x-dead-letter-exchange'    => '',
          'x-dead-letter-routing-key' => main_queue_name
        })
      end

      def callback(delivery_info, properties, payload, queue_name, retry_config, &block)
        event_name  = delivery_info.routing_key
        retry_count = (properties.headers&.dig('x-event-people-retries') || 0).to_i

        event = EventPeople::Event.new(event_name, payload, 1.0, retry_count: retry_count)

        context = EventPeople::Broker::Rabbit::RabbitContext.new(
          channel,
          delivery_info,
          retry_count:      retry_count,
          max_retries:      retry_config[:max_attempts],
          delay_strategy:   retry_config[:delay_strategy],
          dlq_name:         retry_config[:dlq_name],
          queue_name:       queue_name,
          original_payload: payload
        )

        block.call(event, context)
      end

      def topic
        Rabbit::Topic.topic(channel)
      end

      def main_queue_options
        {
          durable:   true,
          arguments: { 'x-dead-letter-exchange' => "#{EventPeople::Config::APP_NAME}_dlx" }
        }
      end

      def queue_name(routing_key)
        "#{EventPeople::Config::APP_NAME.downcase}-#{routing_key.downcase}"
      end
    end
  end
end

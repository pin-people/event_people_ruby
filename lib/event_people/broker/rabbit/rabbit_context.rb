module EventPeople
  module Broker
    class Rabbit::RabbitContext < EventPeople::Broker::Context
      attr_reader :max_retries, :dlq_name

      def initialize(channel, delivery_info, retry_count: 0, max_retries: nil, delay_strategy: nil, dlq_name: nil, queue_name: nil, original_payload: nil)
        @channel          = channel
        @delivery_info    = delivery_info
        @retry_count      = retry_count.to_i
        @max_retries      = (max_retries || EventPeople::Config::MAX_ATTEMPTS).to_i
        @delay_strategy   = delay_strategy || EventPeople::Config::DELAY_STRATEGY
        @dlq_name         = dlq_name || EventPeople::Config::DLQ_NAME
        @queue_name       = queue_name
        @original_payload = original_payload
      end

      def is_last_retry
        @retry_count >= @max_retries - 1
      end

      def success
        @channel.ack(@delivery_info.delivery_tag, false)
      end

      def fail
        retry_manager = Rabbit::RetryManager.new(@max_retries, @delay_strategy)

        if retry_manager.should_retry?(@retry_count)
          delay = retry_manager.get_next_delay(@retry_count)
          begin
            @channel.default_exchange.publish(
              @original_payload,
              routing_key: "#{@queue_name}_retry",
              expiration: delay.to_s,
              headers: { 'x-event-people-retries' => @retry_count + 1 }
            )
            @channel.ack(@delivery_info.delivery_tag, false)
          rescue => e
            # If publish+ack fails, nack so the message is redelivered from the main queue.
            # This risks duplication if publish succeeded but ack failed, which is an inherent
            # AMQP at-least-once limitation. We prefer redelivery over silent loss.
            begin
              @channel.nack(@delivery_info.delivery_tag, false, true)
            rescue
              # Channel may already be closed; nothing we can do.
            end
            raise e
          end
        else
          @channel.nack(@delivery_info.delivery_tag, false, false)
        end
      end

      def reject
        @channel.reject(@delivery_info.delivery_tag, false)
      end
    end
  end
end

module EventPeople
  module Broker
    class Rabbit::RabbitContext < EventPeople::Broker::Context
      attr_reader :max_retries, :dlq_name

      def initialize(channel, delivery_info, retry_count: 0, max_retries: nil, initial_delay: nil, delay_strategy: nil, dlq_name: nil, queue_name: nil, original_payload: nil)
        @channel          = channel
        @delivery_info    = delivery_info
        @retry_count      = retry_count.to_i
        @max_retries      = (max_retries || EventPeople::Config.max_attempts).to_i
        @initial_delay    = initial_delay || EventPeople::Config.initial_delay
        @delay_strategy   = delay_strategy || EventPeople::Config.delay_strategy
        @dlq_name         = dlq_name || EventPeople::Config.dlq_name
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
        retry_manager = Rabbit::RetryManager.new(@max_retries, @delay_strategy, initial_delay: @initial_delay)

        if retry_manager.should_retry?(@retry_count)
          delay = retry_manager.get_next_delay(@retry_count)
          begin
            @channel.default_exchange.publish(
              @original_payload,
              routing_key: "#{@queue_name}_retry",
              expiration: delay.to_s,
              headers: { 'x-event-people-retries' => @retry_count + 1 }
            )
          rescue => e
            # Publish failed — nack without requeue to avoid an infinite redelivery loop.
            # Requeuing without incrementing x-event-people-retries would loop forever.
            begin
              @channel.nack(@delivery_info.delivery_tag, false, false)
            rescue
              # Channel may already be closed; nothing we can do.
            end
            raise e
          end
          begin
            @channel.ack(@delivery_info.delivery_tag, false)
          rescue
            # Publish already succeeded; swallow ack errors. The message may be redelivered
            # once (at-least-once), but that is safer than nacking when a retry copy
            # is already enqueued.
          end
        else
          # Retries exhausted: publish the message to the application-level DLQ + ack.
          publish_to_dlq
        end
      end

      def reject
        publish_to_dlq
      end

      private

      # Forwards the current message body to the application-level DLQ via the default
      # exchange (routing key = DLQ name), so failed messages are dead-lettered without
      # relying on a broker dead-letter-exchange. Falls back to nack(requeue=false) when
      # no channel/DLQ is configured or the publish fails.
      def publish_to_dlq
        if @channel.nil? || @dlq_name.nil? || @dlq_name.empty?
          safe_nack
          return
        end

        begin
          @channel.default_exchange.publish(
            @original_payload,
            routing_key: @dlq_name,
            persistent:  true,
            headers:     { 'x-event-people-retries' => @retry_count }
          )
        rescue
          safe_nack
          return
        end

        begin
          @channel.ack(@delivery_info.delivery_tag, false)
        rescue
          # Publish already succeeded; swallow ack errors (at-least-once on the DLQ).
        end
      end

      def safe_nack
        @channel.nack(@delivery_info.delivery_tag, false, false)
      rescue
        # Channel may already be closed; nothing we can do.
      end
    end
  end
end

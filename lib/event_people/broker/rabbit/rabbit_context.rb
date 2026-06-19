module EventPeople
  module Broker
    class Rabbit::RabbitContext < EventPeople::Broker::Context
      attr_reader :max_retries, :dlq_name

      # Builds a context for a single delivered message, resolving retry/DLQ
      # settings from the explicit arguments or falling back to EventPeople::Config.
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

      # Returns true when the current attempt is the final allowed retry.
      def is_last_retry
        @retry_count >= @max_retries - 1
      end

      # Acknowledges the message as successfully processed.
      def success
        @channel.ack(@delivery_info.delivery_tag, false)
      end

      # Handles a processing failure: republishes to the retry queue with backoff
      # while retries remain, otherwise dead-letters the message to the app-level DLQ.
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

      # Rejects the message outright, dead-lettering it to the app-level DLQ.
      def reject
        publish_to_dlq
      end

      private

      # Forwards the current message body to the application-level DLQ via the default
      # exchange (routing key = DLQ name), so failed messages are dead-lettered without
      # relying on a broker dead-letter-exchange. Falls back to nack(requeue=false) when
      # no channel/DLQ is configured or the publish fails.
      def publish_to_dlq
        return safe_nack if @channel.nil? || @dlq_name.nil? || @dlq_name.empty?

        return safe_nack unless publish_dlq_message

        ack_after_dlq
      end

      # Publishes the message body to the DLQ. Returns true on success, false if the
      # publish raised (so the caller can fall back to nack).
      def publish_dlq_message
        @channel.default_exchange.publish(
          @original_payload,
          routing_key: @dlq_name,
          persistent: true,
          headers: { 'x-event-people-retries' => @retry_count }
        )
        true
      rescue StandardError
        false
      end

      # Acks the original delivery after a successful DLQ publish; swallows ack errors
      # (at-least-once on the DLQ) since the message is already safely enqueued.
      def ack_after_dlq
        @channel.ack(@delivery_info.delivery_tag, false)
      rescue StandardError
        # Publish already succeeded; swallow ack errors (at-least-once on the DLQ).
      end

      # Nacks the message without requeue, ignoring errors from an already-closed
      # channel. Used as the fallback when publishing to the DLQ is not possible.
      def safe_nack
        @channel.nack(@delivery_info.delivery_tag, false, false)
      rescue StandardError
        # Channel may already be closed; nothing we can do.
      end
    end
  end
end

module EventPeople
  module Broker
    class Rabbit::RetryManager
      INITIAL_DELAY = (ENV['RABBIT_EVENT_PEOPLE_RETRY_TTL_MS'] || 1000).to_i
      MAX_DELAY = 600_000

      def initialize(max_attempts, delay_strategy = 'exponential')
        @max_attempts   = max_attempts
        @delay_strategy = delay_strategy
      end

      def should_retry?(retry_count)
        retry_count < @max_attempts
      end

      def get_next_delay(retry_count)
        if @delay_strategy == 'fixed'
          INITIAL_DELAY
        else
          [INITIAL_DELAY * (5**retry_count), MAX_DELAY].min
        end
      end
    end
  end
end

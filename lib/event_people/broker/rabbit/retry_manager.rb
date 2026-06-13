module EventPeople
  module Broker
    class Rabbit::RetryManager
      MAX_DELAY = 600_000

      def initialize(max_attempts, delay_strategy = 'exponential', initial_delay: nil)
        @max_attempts   = max_attempts
        @delay_strategy = delay_strategy
        @initial_delay  = initial_delay || EventPeople::Config.initial_delay
      end

      def should_retry?(retry_count)
        retry_count < @max_attempts
      end

      def get_next_delay(retry_count)
        if @delay_strategy == 'fixed'
          @initial_delay
        else
          [@initial_delay * (5**retry_count), MAX_DELAY].min
        end
      end
    end
  end
end

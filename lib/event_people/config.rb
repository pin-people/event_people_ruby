module EventPeople
  class Config
    APP_NAME = ENV['RABBIT_EVENT_PEOPLE_APP_NAME']
    TOPIC    = ENV['RABBIT_EVENT_PEOPLE_TOPIC_NAME']
    VHOST    = ENV['RABBIT_EVENT_PEOPLE_VHOST']
    URL      = ENV['RABBIT_URL']
    FULL_URL = "#{ENV['RABBIT_URL']}/#{ENV['RABBIT_EVENT_PEOPLE_VHOST']}"

    # Hardcoded defaults — no longer sourced from env vars (spec v1.2.0).
    DEFAULT_MAX_ATTEMPTS   = 3
    DEFAULT_INITIAL_DELAY  = 1000
    DEFAULT_DELAY_STRATEGY = 'exponential'

    class << self
      # Optional. Sets global retry defaults in code.
      # Options: { max_attempts, initial_delay, delay_strategy, dlq_name }
      # Connection attributes (app_name, url, vhost, topic) are always read from env vars.
      def configure(options = {})
        @max_attempts   = options[:max_attempts]&.to_i
        @initial_delay  = options[:initial_delay]&.to_i
        @delay_strategy = options[:delay_strategy]
        @dlq_name       = options[:dlq_name]
      end

      def max_attempts
        @max_attempts || DEFAULT_MAX_ATTEMPTS
      end

      def initial_delay
        @initial_delay || DEFAULT_INITIAL_DELAY
      end

      def delay_strategy
        @delay_strategy || DEFAULT_DELAY_STRATEGY
      end

      def dlq_name
        @dlq_name || "#{APP_NAME}_dlq"
      end

      def broker
        EventPeople::Broker::Rabbit
      end

      def get_retry_config
        {
          max_attempts:   max_attempts,
          initial_delay:  initial_delay,
          delay_strategy: delay_strategy,
          dlq_name:       dlq_name
        }
      end
    end
  end
end

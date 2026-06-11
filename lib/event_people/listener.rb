require 'bunny'

module EventPeople
  class Listener
    def self.on(event_name, max_attempts: nil, delay_strategy: nil, dlq_name: nil, &block)
      new.on(event_name, max_attempts: max_attempts, delay_strategy: delay_strategy, dlq_name: dlq_name, &block)
    end

    def on(event_name, max_attempts: nil, delay_strategy: nil, dlq_name: nil, &block)
      raise(MissingAttributeError, 'Event name must be present') unless event_name&.size&.positive?

      event_name = consumed_event_name(event_name)

      retry_config = EventPeople::Config.get_retry_config.merge(
        max_attempts:   max_attempts   || EventPeople::Config::MAX_ATTEMPTS,
        delay_strategy: delay_strategy || EventPeople::Config::DELAY_STRATEGY,
        dlq_name:       dlq_name       || EventPeople::Config::DLQ_NAME
      )

      EventPeople::Config.broker.consume(event_name, retry_config: retry_config, &block)
    end

    private

    def consumed_event_name(event_name)
      event_name.split('.').size == 3 ? "#{event_name}.all" : event_name
    end
  end
end

require 'bunny'

module EventPeople
  class Listener
    def self.on(event_name, listener_class: nil, &block)
      new.on(event_name, listener_class: listener_class, &block)
    end

    def on(event_name, listener_class: nil, &block)
      raise(MissingAttributeError, 'Event name must be present') unless event_name&.size&.positive?

      event_name = consumed_event_name(event_name)

      retry_config = retry_config_for(listener_class)

      EventPeople::Config.broker.consume(event_name, retry_config: retry_config, &block)
    end

    private

    def consumed_event_name(event_name)
      event_name.split('.').size == 3 ? "#{event_name}.all" : event_name
    end

    # Resolve retry config: listener class attributes > Config defaults.
    def retry_config_for(listener_class)
      base = EventPeople::Config.get_retry_config

      return base unless listener_class.respond_to?(:retry_config)

      listener_config = listener_class.retry_config
      base.merge(listener_config.reject { |_, v| v.nil? })
    end
  end
end

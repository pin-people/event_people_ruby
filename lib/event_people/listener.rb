require 'bunny'

module EventPeople
  class Listener
    def self.on(event_name, &block)
      new.on(event_name, &block)
    end

    def on(event_name, &block)
      raise(MissingAttributeError, 'Event name must be present') unless event_name&.size&.positive?

      event_name = consumed_event_name(event_name)

      EventPeople::Config.broker.consume(event_name, &block)
    end

    private

    def consumed_event_name(event_name)
      event_name.split('.').size == 3 ? "#{event_name}.all" : event_name
    end
  end
end

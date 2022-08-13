require 'json'

module EventPeople
  # Public: An class which decorates el-rabbit topic creation.
  #
  class Emitter
    # Public: Produces a event on the Broker.
    #
    # event - The event to be produced.
    #
    # Returns the Event.
    def self.trigger(*events)
      events.flatten.each_with_index do |event, index|
        raise(MissingAttributeError, "Event on position #{index} must have a body") unless event.body?
        raise(MissingAttributeError, "Event on position #{index} must have a name") unless event.name?
      end

      EventPeople::Config.broker.produce(events.flatten)

      events
    end
  end
end

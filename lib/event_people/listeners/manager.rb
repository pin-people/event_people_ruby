# Module responsible for managing all listeners
module EventPeople
  module Listeners
    module Manager
      class << self
        def bind_all_listeners
          listener_configurations.each do |config|
            EventPeople::Listener.on(config[:routing_key]) do |event, context|
              config[:listener_class].new(context.channel, context.delivery_info).callback(config[:method], event)
            end
          end
        end

        def register_listener_configuration(configuration)
          listener_configurations.push(configuration)
        end

        private

        def listener_configurations
          @listener_configurations ||= []
        end
      end
    end
  end
end

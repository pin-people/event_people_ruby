module EventPeople
  module Listeners
    class Base
      def initialize(context)
        @context = context
      end

      def callback(method_name, event)
        send method_name, event
      end

      def success!
        @context.success!
      end

      def fail!
        @context.fail!
      end

      def reject!
        @context.reject!
      end

      def self.bind(method, event_name)
        app_name = ENV['RABBIT_EVENT_PEOPLE_APP_NAME'].downcase
        splitted_event_name = event_name.split('.')

        if splitted_event_name.size <= 3
          Manager.register_listener_configuration(
            {
              listener_class: self,
              method: method,
              routing_key: fixed_event_name(event_name, 'all')
            }
          )
          Manager.register_listener_configuration(
            {
              listener_class: self,
              method: method,
              routing_key: fixed_event_name(event_name, app_name)
            }
          )
        else
          Manager.register_listener_configuration(
            {
              listener_class: self,
              method:,
              routing_key: fixed_event_name(event_name, app_name)
            }
          )
        end
      end

      def self.fixed_event_name(event_name, postfix)
        case event_name&.split('.')&.size
        when 4
          parts = event_name.split('.')

          "#{parts[0..2].join('.')}.#{postfix}"
        when nil
          event_name
        else
          "#{event_name}.#{postfix}"
        end
      end
    end
  end
end

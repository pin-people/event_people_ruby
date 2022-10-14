module EventPeople
  module Listeners
    class Base
      attr_reader :channel, :delivery_info

      def initialize(channel, delivery_info)
        @channel = channel
        @delivery_info = delivery_info
      end

      def callback(method_name, event)
        send method_name, event
      end

      def success!
        channel.ack(delivery_info.delivery_tag, false)
      end

      def fail!
        channel.nack(delivery_info.delivery_tag, false, true)
      end

      def reject!
        channel.reject(delivery_info.delivery_tag, false)
      end

      def self.bind(method, event_name)
        app_name = ENV['RABBIT_EVENT_PEOPLE_APP_NAME'].downcase
        splitted_event_name = event_name.split('.')

        if splitted_event_name.size == 3
          Manager.register_listener_configuration(
            {
              listener_class: self,
              method:,
              routing_key: fixed_event_name(event_name, 'all')
            }
          )
          Manager.register_listener_configuration(
            {
              listener_class: self,
              method:,
              routing_key: fixed_event_name(event_name, app_name)
            }
          )
        else
          Manager.register_listener_configuration(
            {
              listener_class: self,
              method:,
              routing_key: event_name
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

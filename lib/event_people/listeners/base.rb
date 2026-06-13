module EventPeople
  module Listeners
    class Base
      # ---------------------------------------------------------------------------
      # Class-level retry DSL (spec v1.2.0)
      # Subclasses may declare any of these to override Config defaults:
      #
      #   class MyListener < EventPeople::Listeners::Base
      #     self.max_attempts   = 5
      #     self.initial_delay  = 500
      #     self.delay_strategy = 'fixed'
      #     self.dlq_name       = 'my_dlq'
      #   end
      # ---------------------------------------------------------------------------
      class << self
        attr_writer :max_attempts, :initial_delay, :delay_strategy, :dlq_name

        def max_attempts;   defined?(@max_attempts)   ? @max_attempts   : nil; end
        def initial_delay;  defined?(@initial_delay)  ? @initial_delay  : nil; end
        def delay_strategy; defined?(@delay_strategy) ? @delay_strategy : nil; end
        def dlq_name;       defined?(@dlq_name)       ? @dlq_name       : nil; end

        # Returns only explicitly set class-level retry attrs (nils excluded by Listener).
        def retry_config
          {
            max_attempts:   max_attempts,
            initial_delay:  initial_delay,
            delay_strategy: delay_strategy,
            dlq_name:       dlq_name
          }
        end

        def bind(method, event_name)
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
                method: method,
                routing_key: fixed_event_name(event_name, app_name)
              }
            )
          end
        end

        def fixed_event_name(event_name, postfix)
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

      # ---------------------------------------------------------------------------
      # Instance interface
      # ---------------------------------------------------------------------------

      attr_reader :context

      def initialize(context)
        @context = context
      end

      def callback(method_name, event)
        send method_name, event
      end

      def success
        @context.success
      end

      def fail
        @context.fail
      end

      def reject
        @context.reject
      end

      def success!
        warn '[DEPRECATED] EventPeople: `success!` is deprecated, use `success` instead. Will be removed in a future version.'
        success
      end

      def fail!
        warn '[DEPRECATED] EventPeople: `fail!` is deprecated, use `fail` instead. Will be removed in a future version.'
        self.fail
      end

      def reject!
        warn '[DEPRECATED] EventPeople: `reject!` is deprecated, use `reject` instead. Will be removed in a future version.'
        reject
      end
    end
  end
end

module EventPeople
  module Broker
    class Context
      def success
        raise NotImplementedError.new('Must be implemented')
      end

      def fail
        raise NotImplementedError.new('Must be implemented')
      end

      def reject
        raise NotImplementedError.new('Must be implemented')
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

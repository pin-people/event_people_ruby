module EventPeople
  module Broker
    class Context
      def success!
        raise NotImplementedError.new('Must be implemented')
      end

      def fail!
        raise NotImplementedError.new('Must be implemented')
      end

      def reject!
        raise NotImplementedError.new('Must be implemented')
      end
    end
  end
end

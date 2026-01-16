module Ralph
  module Agents
    class Base
      def verify(context)
        raise NotImplementedError
      end

      def execute(context)
        raise NotImplementedError
      end

      def complete?(context)
        raise NotImplementedError
      end
    end
  end
end

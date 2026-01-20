# frozen_string_literal: true
module Crayons
  module Clients
    class Base
      def initialize(api_key:, url:, model:)
        raise NotImplementedError, "#{self.class} must implement #initialize"
      end

      def chat(system:, messages:, tools:)
        raise NotImplementedError, "#{self.class} must implement #chat"
      end
    end
  end
end

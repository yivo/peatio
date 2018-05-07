module Serializers
  module EventAPI
    class OrderCreated
      def call(order)
        { created_at: order.created_at.iso8601 }
      end

      class << self
        def call(order)
          new.call(order)
        end
      end
    end
  end
end

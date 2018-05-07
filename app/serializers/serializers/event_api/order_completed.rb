module Serializers
  module EventAPI
    class OrderCompleted
      def call(order)
        { created_at:   order.created_at.iso8601,
          completed_at: order.updated_at.iso8601 }
      end

      class << self
        def call(order)
          new.call(order)
        end
      end
    end
  end
end

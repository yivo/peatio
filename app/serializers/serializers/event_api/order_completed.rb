module Serializers
  module EventAPI
    class OrderCompleted < OrderEvent
      def call(order)
        super.merge! \
          completed_at: order.updated_at.iso8601
      end
    end
  end
end

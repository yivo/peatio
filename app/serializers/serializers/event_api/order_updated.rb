module Serializers
  module EventAPI
    class OrderUpdated
      def call(order)
        { market:     order.market.id,
          created_at: order.created_at.iso8601,
          updated_at: order.updated_at.iso8601 }
      end

      class << self
        def call(order)
          new.call(order)
        end
      end
    end
  end
end

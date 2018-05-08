module Serializers
  module EventAPI
    class OrderUpdated < OrderEvent
      def call(order)
        super.merge! \
          previous_income_amount:  order.previous_changes.fetch('volume')[0].to_s('F'),
          previous_outcome_amount: (order.previous_changes.fetch('locked')[0] * order.price).to_s('F'),
          updated_at:              order.updated_at.iso8601
      end
    end
  end
end

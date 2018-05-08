module Serializers
  module EventAPI
    class OrderEvent
      def call(order)
        { market:                 order.market.id,
          type:                   type(order),
          trader_uid:             order.member.uid,
          income_unit:            Currency.find(buy?(order) ? order.ask : order.bid).code,
          income_fee_type:        'relative',
          income_fee_value:       order.fee.to_s('F'),
          outcome_unit:           Currency.find(buy?(order) ? order.bid : order.ask).code,
          outcome_fee_type:       'relative',
          outcome_fee_value:      '0.0',
          initial_income_amount:  order.origin_volume.to_s('F'),
          current_income_amount:  order.volume.to_s('F'),
          initial_outcome_amount: (order.origin_volume * order.price).to_s('F'),
          current_outcome_amount: (order.volume * order.price).to_s('F'),
          strategy:               order.ord_type,
          price:                  order.price.to_s('F'),
          state:                  state(order),
          trades_count:           order.trades_count,
          created_at:             order.created_at.iso8601 }
      end

      class << self
        def call(order)
          new.call(order)
        end
      end

    private
      def state(order)
        case order.state
          when Order::CANCEL then 'canceled'
          when Order::DONE   then 'completed'
          else 'open'
        end
      end

      def type(order)
        OrderBid === order ? 'buy' : 'sell'
      end

      def buy?(order)
        type(order) == 'buy'
      end

      def sell?(order)
        !buy?(order)
      end

      def previous_income_amount(order)
        if order.previous_changes.key?('volume')
          order.previous_changes['volume'][0]
        else
          order.volume.to_s('F')
        end.to_s('F')
      end

      def previous_outcome_amount(order)
        if order.previous_changes.key?('locked')
          order.previous_changes['locked'][0]
        else
          order.volume * order.price
        end.to_s('F')
      end
    end
  end
end

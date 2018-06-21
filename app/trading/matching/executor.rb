# encoding: UTF-8
# frozen_string_literal: true

require_relative 'constants'

module Matching
  class Executor
    def initialize(payload)
      @payload = payload
      # NOTE: Run matching engine for disabled markets.
      @market  = Market.find(payload[:market_id])
      @price   = payload[:strike_price].to_d
      @volume  = payload[:volume].to_d
      @funds   = payload[:funds].to_d
    end

    def execute
      execute!
    rescue TradeExecutionError => e
      AMQPQueue.enqueue(:trade_error, e.options)
      [@ask, @bid].each do |order|
        order.with_lock do
          next unless order.state == Order::WAIT
          AMQPQueue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
        end
      end
      report_exception_to_screen(e)
      false
    end

    def execute!
      create_trade_and_strike_orders
      publish_trade
      @trade
    end

  private

    def validate!
      raise_error(3001, 'Ask price exceeds strike price.') if @ask.ord_type == 'limit' && @ask.price > @price
      raise_error(3002, 'Bid price is less than strike price.') if @bid.ord_type == 'limit' && @bid.price < @price
      raise_error(3003, 'Ask state isn\'t equal to «wait».') unless @ask.state == Order::WAIT
      raise_error(3004, 'Bid state isn\'t equal to «wait».') unless @bid.state == Order::WAIT
      unless @funds > ZERO && [@ask.volume, @bid.volume].min >= @volume
        raise_error(3005, 'Not enough funds.')
      end
    end

    def trend
      @price >= @market.latest_price ? 'up' : 'down'
    end

    def create_trade_and_strike_orders
      @trade = Trade.new \
        ask:           @ask,
        ask_member_id: @ask.member_id,
        bid:           @bid,
        bid_member_id: @bid.member_id,
        price:         @price,
        volume:        @volume,
        funds:         @funds,
        market:        @market,
        trend:         trend

      ActiveRecord::Base.transaction do
        @ask = OrderAsk.lock.find(@payload[:ask_id])
        @bid = OrderBid.lock.find(@payload[:bid_id])
        validate!
        @bid.strike @trade
        @ask.strike @trade
      end

      @trade.save(validate: false)
    end

    def publish_trade
      AMQPQueue.publish :trade, @trade.as_json, {
        headers: {
          market:        @market.id,
          ask_member_id: @ask.member_id,
          bid_member_id: @bid.member_id
        }
      }
    end

    def raise_error(code, message)
      raise TradeExecutionError.new \
        ask:     @ask.attributes,
        bid:     @bid.attributes,
        price:   @price,
        volume:  @volume,
        funds:   @funds,
        code:    code,
        message: message
    end
  end
end

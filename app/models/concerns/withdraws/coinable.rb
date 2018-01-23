module Withdraws
  module Coinable
    extend ActiveSupport::Concern

    def set_fee
      self.fee = "0.0001".to_d
    end

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def as_json(options={})
      super(options).merge({
        blockchain_url: blockchain_url
      })
    end

  end
end


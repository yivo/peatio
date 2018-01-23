module Worker
  class DepositCoin

    def process(payload)
      payload.symbolize_keys!

      channel = DepositChannel.find_by_key(payload.fetch(:channel_key))
      tx      = channel.currency_obj.api.load_transaction!(payload.fetch(:txid))

      deposit!(channel, tx)
    end

    def deposit!(channel, tx)
      return if tx[:amount] < 0
      return unless PaymentAddress.where(currency: channel.currency_obj.id, address: tx[:address]).exists?
      return if PaymentTransaction::Normal.where(txid: tx[:id], txout: tx[:address]).exists?

      ActiveRecord::Base.transaction do

        tx = PaymentTransaction::Normal.create! \
          txid: tx[:id],
          txout: 1,
          address: tx[:address],
          amount: tx[:amount],
          confirmations: tx[:confirmations],
          receive_at: Time.at(tx[:timereceived]).to_datetime,
          currency: channel.currency

        deposit = channel.kls.create! \
          payment_transaction_id: tx.id,
          txid: tx.txid,
          txout: tx.txout,
          amount: tx.amount,
          member: tx.member,
          account: tx.account,
          currency: tx.currency,
          confirmations: tx.confirmations

        deposit.submit!
      end
    rescue => e
      Rails.logger.error 'Failed to process deposit.'
      Rails.logger.debug { tx.inspect }
      report_exception(e)
    end
  end
end

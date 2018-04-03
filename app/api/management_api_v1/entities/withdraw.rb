module ManagementAPIv1
  module Entities
    class Withdraw < Base
      expose :tid, documentation: { type: Integer, desc: 'The shared transaction ID.' }
      expose(:currency, documentation: { type: String, desc: 'The currency code.' }) { |w| w.currency.code }
      expose(:uid, documentation: { type: String, desc: 'The shared user ID.' }) { |w| w.member.authentications.barong.first.uid }
      expose(:type, documentation: { type: String, desc: 'The withdraw type (fiat or coin).' }) { |w| w.class.name.demodulize.underscore }
      expose :amount, documentation: { type: String, desc: 'The withdraw amount excluding fee.' }, format_with: :decimal
      expose :fee, documentation: { type: String, desc: 'The exchange fee.' }, format_with: :decimal
      expose :txid, as: :blockchain_txid, documentation: { type: String, desc: 'The transaction ID on the Blockchain (coin only).' }, if: -> (w, _) { w.coin? }
      expose :bid, documentation: { type: String, desc: 'The beneficiary ID or wallet address on the Blockchain.' }
      expose :aasm_state, as: :state, documentation: { type: String, desc: 'The withdraw state.' }
      expose :created_at, format_with: :iso8601, documentation: { type: String, desc: 'The datetime when withdraw was created.' }
    end
  end
end

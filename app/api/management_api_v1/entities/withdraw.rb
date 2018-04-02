module ManagementAPIv1
  module Entities
    class Withdraw < Base
      expose :id, documentation: { type: Integer, desc: 'The withdraw ID.' }
      expose(:currency, documentation: { type: String, desc: 'The currency code.' }) { |w| w.currency.code }
      expose(:member, documentation: { type: String, desc: 'The member UID on Barong.' }) { |w| w.member.authentications.barong.first.uid }
      expose(:type, documentation: { type: String, desc: 'The withdraw type (fiat or coin).' }) { |w| w.class.name.demodulize.underscore }
      expose :amount, documentation: { type: String, desc: 'The withdraw amount excluding fee.' }, format_with: :decimal
      expose :fee, documentation: { type: String, desc: 'The exchange fee.' }, format_with: :decimal
      expose :txid, documentation: { type: String, desc: 'The transaction ID (coin only).' }, if: -> (w, _) { w.coin? }
      expose :destination, using: ManagementAPIv1::Entities::WithdrawDestination
      expose :aasm_state, as: :state, documentation: { type: String, desc: 'The withdraw state.' }
      expose :created_at, format_with: :iso8601, documentation: { type: String, desc: 'The datetime when withdraw was created.' }
    end
  end
end

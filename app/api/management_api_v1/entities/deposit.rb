module ManagementAPIv1
  module Entities
    class Deposit < Base
      expose :id, documentation: { type: Integer, desc: 'The deposit ID.' }
      expose(:currency, documentation: { type: String, desc: 'The currency code.' }) { |d| d.currency.code }
      expose(:uid, documentation: { type: String, desc: 'The member UID on Barong.' }) { |w| w.member.authentications.barong.first.uid }
      expose(:type, documentation: { type: String, desc: 'The deposit type (fiat or coin).' }) { |d| d.class.name.demodulize.underscore }
      expose :amount, documentation: { type: String, desc: 'The deposit amount.' }, format_with: :decimal
      expose :aasm_state, as: :state, documentation: { type: String, desc: 'The deposit state.' }
      expose :created_at, format_with: :iso8601, documentation: { type: String, desc: 'The datetime when deposit was created.' }
      expose :done_at, as: :completed_at, format_with: :iso8601, documentation: { type: String, desc: 'The datetime when deposit was completed.' }
      expose :txid, if: -> (d, _) { d.coin? }, documentation: { type: String, desc: 'The transaction ID (coin only).' }
    end
  end
end

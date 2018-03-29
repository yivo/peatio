module ManagementAPIv1
  module Entities
    class Withdraw < Base
      expose :id, documentation: { type: Integer, desc: 'The withdraw ID.' }
      expose(:currency, documentation: { type: String, desc: 'The currency code.' }) { |w| w.currency.code }
      expose(:type, documentation: { type: String, desc: 'The withdraw type (fiat or coin).' }) { |w| w.class.name.demodulize.underscore }
      expose :sum, as: :amount, documentation: { type: String, desc: 'The withdraw amount excluding fee.' }
      expose :fee, documentation: { type: String, desc: 'The exchange fee.' }
      expose :txid, documentation: { type: String, desc: 'The transaction ID.' }, unless: :coin?
      expose :destination, using: ManagementAPIv1::Entities::WithdrawDestination
      expose :state, documentation: { type: String, desc: 'The withdraw state.' }
      expose :created_at, format_with: :iso8601
    end
  end
end

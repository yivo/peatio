module ManagementAPIv1
  module Entities
    class Deposit < Base
      expose :id
      expose(:currency) { |d| d.currency.code }
      expose(:type) { |d| d.class.name.demodulize.underscore }
      expose :amount, format_with: :decimal
      expose :aasm_state, as: :state
      expose :created_at, format_with: :iso8601
      expose :done_at, as: :completed_at, format_with: :iso8601
      expose :txid, if: -> (d, _) { d.coin? }
      expose :confirmations, if: -> (d, _) { d.coin? }
    end
  end
end

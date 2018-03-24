module ManagementAPIv1
  module Entities
    class Deposit < Base
      expose :id
      expose(:currency) { |deposit| deposit.currency.code }
      expose(:type) { |deposit| deposit.class.demodulize.underscore }
      expose :amount, format_with: :decimal
      expose :aasm_state, as: :state
      expose :created_at, format_with: :iso8601
      expose :done_at, as: :completed_at, format_with: :iso8601
      expose :txid, if: -> (deposit) { deposit.coin? }
      expose :confirmations, if: -> (deposit) { deposit.coin? }
    end
  end
end

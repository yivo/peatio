FactoryBot.define do
  factory :deposit do
    member { create(:member, :verified_identity) }
    fund_uid { Faker::Lorem.characters }
    fund_extra { Faker::Lorem.characters }
    amount { (100..10_000).to_a.sample.to_d }
    txid { Faker::Lorem.characters(16) }

    trait :btc_account do
      currency { Currency.find_by!(code: :btc) }
      account { member.get_account(:btc) }
      payment_transaction { create(:payment_transaction) }
    end

    trait :usd_account do
      currency { Currency.find_by!(code: :usd) }
      account { member.get_account(:usd) }
    end

    factory :deposit_btc, class: 'Deposits::Coin', traits: [:btc_account]
    factory :deposit_usd, class: 'Deposits::Fiat', traits: [:usd_account]
  end
end

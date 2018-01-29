FactoryBot.define do
  factory :fund_source do
    extra 'bitcoin'
    uid { Faker::Bitcoin.address }
    is_locked false
    currency 'btc'

    member { create(:member) }

    trait :cad do
      extra 'bc'
      uid '123412341234'
      currency 'cad'
    end

    factory :cad_fund_source, traits: [:cad]
    factory :btc_fund_source
  end
end

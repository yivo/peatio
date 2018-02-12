FactoryBot.define do
  factory :member do
    email { Faker::Internet.email }

    trait :verified do
      # TODO
      after :create do |member|

      end
    end

    trait :admin do
      after :create do |member|
        ENV['ADMIN'] = (Member.admins << member.email).join(',')
      end
    end

    factory :verified_member, traits: %i[ verified ]
    factory :admin_member, traits: %i[ admin ]
  end
end

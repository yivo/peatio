FactoryBot.define do
  factory :member do
    email { Faker::Internet.email }
    name { Faker::Name.name }
    nickname { Faker::Internet.user_name }
    level { :unverified }

    trait :verified do
      after :create do |member|
        member.level = :identity_verified
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

FactoryBot.define do
  factory :order_bid do
    bid :cad
    ask :btc
    currency :btccad
    state :wait
    source 'Web'
    ord_type 'limit'
    price { '1'.to_d }
    volume { '1'.to_d }
    origin_volume { volume }
    locked { price.to_d * volume.to_d }
    origin_locked { locked }
  end

  factory :order_ask do
    bid :cad
    ask :btc
    currency :btccad
    state :wait
    source 'Web'
    ord_type 'limit'
    price { '1'.to_d }
    volume { '1'.to_d }
    origin_volume { volume }
    locked { volume }
    origin_locked { locked }
  end
end

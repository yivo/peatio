describe Serializers::EventAPI::OrderCompleted do
  let(:seller) { create(:member, :verified_identity, :barong) }

  let :order_ask do
    create :order_ask, \
      bid:           Currency.find_by!(code: :usd).id,
      ask:           Currency.find_by!(code: :btc).id,
      market:        Market.find(:btcusd),
      state:         :wait,
      source:        'Web',
      ord_type:      :limit,
      price:         '0.03'.to_d,
      volume:        '100.0',
      origin_volume: '100.0',
      locked:        '100.0',
      origin_locked: '100.0',
      member:        seller
  end

  subject { order_ask }

  let(:created_at) { 10.minutes.ago }
  let(:completed_at) { Time.current }

  before do
    seller.ac(:btc).plus_funds('100.0'.to_d)
    seller.ac(:btc).lock_funds('100.0'.to_d)
  end

  before { Order.any_instance.expects(:created_at).returns(created_at).at_least_once }
  before { Order.any_instance.expects(:updated_at).returns(completed_at).at_least_once }

  before do
    EventAPI.expects(:notify).with('market.btcusd.order_created', anything).once
    EventAPI.expects(:notify).with('market.btcusd.order_completed', {
      market:       'btcusd',
      created_at:   created_at.iso8601,
      completed_at: completed_at.iso8601
    }).once
  end

  it 'publishes event' do
    subject.update! \
    volume:         0,
    locked:         0,
    funds_received: 100,
    trades_count:   1,
    state:          Order::DONE
  end
end

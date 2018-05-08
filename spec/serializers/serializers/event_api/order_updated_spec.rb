describe Serializers::EventAPI::OrderUpdated do
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
  let(:updated_at) { Time.current }

  before do
    seller.ac(:btc).plus_funds('100.0'.to_d)
    seller.ac(:btc).lock_funds('100.0'.to_d)
  end

  before { Order.any_instance.expects(:created_at).returns(created_at).at_least_once }
  before { Order.any_instance.expects(:updated_at).returns(updated_at).at_least_once }

  before do
    EventAPI.expects(:notify).with('market.btcusd.order_created', anything)
    EventAPI.expects(:notify).with('market.btcusd.order_updated', {
      market:                  'btcusd',
      type:                    'sell',
      trader_uid:              seller.uid,
      income_unit:             'usd',
      income_fee_type:         'relative',
      income_fee_value:        '0.0015',
      outcome_unit:            'btc',
      outcome_fee_type:        'relative',
      outcome_fee_value:       '0.0',
      initial_income_amount:   '100.0',
      current_income_amount:   '80.0',
      previous_income_amount:  '100.0',
      initial_outcome_amount:  '3.0',
      current_outcome_amount:  '2.4',
      previous_outcome_amount: '3.0',
      strategy:                'limit',
      price:                   '0.03',
      state:                   'open',
      trades_count:            1,
      created_at:              created_at.iso8601,
      updated_at:              updated_at.iso8601
    }).once
  end

  it 'publishes event' do
    subject.transaction do
      subject.update! \
        volume:         80,
        locked:         80,
        funds_received: 20,
        trades_count:   1
    end
  end
end

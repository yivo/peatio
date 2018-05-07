describe Trade, '.latest_price' do
  context 'no trade' do
    it { expect(Trade.latest_price(:btcusd)).to be_d '0.0' }
  end

  context 'add one trade' do
    let!(:trade) { create(:trade, market_id: :btcusd) }
    it { expect(Trade.latest_price(:btcusd)).to eq(trade.price) }
  end
end

describe Trade, '.collect_side' do
  let(:member) { create(:member, :verified_identity) }
  let(:ask)    { create(:order_ask, member: member) }
  let(:bid)    { create(:order_bid, member: member) }

  let!(:trades) do
    [
      create(:trade, ask: ask, created_at: 2.days.ago),
      create(:trade, bid: bid, created_at: 1.day.ago)
    ]
  end

  it 'should add side attribute on trades' do
    results = Trade.for_member(ask.market_id, member)
    expect(results.size).to eq 2
    expect(results.find { |t| t.id == trades.first.id }.side).to eq 'ask'
    expect(results.find { |t| t.id == trades.last.id  }.side).to eq 'bid'
  end

  it 'should sort trades in reverse creation order' do
    expect(Trade.for_member(ask.market_id, member, order: 'id desc').first).to eq trades.last
  end

  it 'should return 1 trade' do
    results = Trade.for_member(ask.market_id, member, limit: 1)
    expect(results.size).to eq 1
  end

  it 'should return trades from specified time' do
    results = Trade.for_member(ask.market_id, member, time_to: 30.hours.ago)
    expect(results.size).to eq 1
    expect(results.first).to eq trades.first
  end
end

describe Trade, '#for_notify' do
  let(:order_ask) { create(:order_ask) }
  let(:order_bid) { create(:order_bid) }
  let(:trade) { create(:trade, ask: order_ask, bid: order_bid) }

  subject(:notify) { trade.for_notify('ask') }

  it { expect(notify).not_to be_blank }
  it { expect(notify[:kind]).not_to be_blank }
  it { expect(notify[:at]).not_to be_blank }
  it { expect(notify[:price]).not_to be_blank }
  it { expect(notify[:volume]).not_to be_blank }

  it 'should use side as kind' do
    trade.side = 'ask'
    expect(trade.for_notify[:kind]).to eq 'ask'
  end
end

describe Trade, 'Event API' do
  let(:seller) { create(:member, :verified_identity, :barong) }

  let(:buyer) { create(:member, :verified_identity, :barong) }

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

  let :order_bid do
    create :order_bid, \
      bid:           Currency.find_by!(code: :usd).id,
      ask:           Currency.find_by!(code: :btc).id,
      market:        Market.find(:btcusd),
      state:         :wait,
      source:        'Web',
      ord_type:      :limit,
      price:         '0.03'.to_d,
      volume:        '14.0',
      origin_volume: '14.0',
      locked:        '0.42',
      origin_locked: '0.42',
      member:        buyer
  end

  let(:completed_at) { Time.current }

  let :executor do
    ask = Matching::LimitOrder.new(order_ask.to_matching_attributes)
    bid = Matching::LimitOrder.new(order_bid.to_matching_attributes)
    Matching::Executor.new \
      market_id:    :btcusd,
      ask_id:       ask.id,
      bid_id:       bid.id,
      strike_price: '0.03',
      volume:       '14.0',
      funds:        '0.42'
  end

  subject { executor.execute! }

  before do
    seller.ac(:btc).plus_funds('100.0'.to_d)
    seller.ac(:btc).lock_funds('100.0'.to_d)
  end

  before do
    buyer.ac(:usd).plus_funds('100.0'.to_d)
    buyer.ac(:usd).lock_funds('14.0'.to_d)
  end

  before { Trade.any_instance.expects(:created_at).returns(completed_at).at_least_once }

  before do
    EventAPI.expects(:notify).with('market.btcusd.trade', {
      market:                'btcusd',
      price:                 '0.03',
      buyer_uid:             buyer.uid,
      buyer_income_unit:     'btc',
      buyer_income_amount:   '13.979',
      buyer_income_fee:      '0.021',
      buyer_outcome_unit:    'usd',
      buyer_outcome_amount:  '0.42',
      buyer_outcome_fee:     '0.0',
      seller_uid:            seller.uid,
      seller_income_unit:    'usd',
      seller_income_amount:  '0.41937',
      seller_income_fee:     '0.00063',
      seller_outcome_unit:   'btc',
      seller_outcome_amount: '14.0',
      seller_outcome_fee:    '0.0',
      completed_at:          completed_at.iso8601
    }).once
  end

  it('publishes event') { subject }
end

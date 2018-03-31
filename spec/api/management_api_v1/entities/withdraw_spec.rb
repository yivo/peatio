describe ManagementAPIv1::Entities::Withdraw do
  context 'fiat' do
    let(:record) { create(:usd_withdraw).reload }

    subject { OpenStruct.new ManagementAPIv1::Entities::Withdraw.represent(record).serializable_hash }

    it { expect(subject.id).to eq record.id }
    it { expect(subject.currency).to eq 'usd' }
    it { expect(subject.type).to eq 'fiat' }
    it { expect(subject.amount).to eq record.amount.to_s }
    it { expect(subject.fee).to eq record.fee.to_s }
    it { expect(subject.respond_to?(:txid)).to be_falsey }
    it { expect(subject.destination).to be_a_kind_of(Hash) }
    it { expect(subject.state).to eq record.aasm_state }
    it { expect(subject.created_at).to eq record.created_at.iso8601 }
  end

  context 'coin' do
    let(:record) { create(:btc_withdraw) }

    subject { OpenStruct.new ManagementAPIv1::Entities::Withdraw.represent(record).serializable_hash }

    it { expect(subject.id).to eq record.id }
    it { expect(subject.currency).to eq 'btc' }
    it { expect(subject.type).to eq 'coin' }
    it { expect(subject.amount).to eq record.amount.to_s }
    it { expect(subject.fee).to eq record.fee.to_s }
    it { expect(subject.txid).to eq record.txid }
    it { expect(subject.destination).to be_a_kind_of(Hash) }
    it { expect(subject.state).to eq record.aasm_state }
    it { expect(subject.created_at).to eq record.created_at.iso8601 }
  end
end

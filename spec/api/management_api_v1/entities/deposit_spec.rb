describe ManagementAPIv1::Entities::Deposit do
  context 'fiat' do
    let(:record) { create(:deposit_usd) }

    subject { OpenStruct.new ManagementAPIv1::Entities::Deposit.represent(record).serializable_hash }

    it { expect(subject.id).to eq record.id }
    it { expect(subject.currency).to eq 'usd' }
    it { expect(subject.type).to eq 'fiat' }
    it { expect(subject.amount).to eq record.amount.to_s }
    it { expect(subject.state).to eq record.aasm_state }
    it { expect(subject.created_at).to eq record.created_at.iso8601 }
    it { expect(subject.completed_at).to eq record.done_at&.iso8601 }
    it { expect(subject.respond_to?(:txid)).to be_falsey }
    it { expect(subject.respond_to?(:confirmations)).to be_falsey }
  end

  context 'coin' do
    let(:record) { create(:deposit_btc) }

    subject { OpenStruct.new ManagementAPIv1::Entities::Deposit.represent(record).serializable_hash }

    it { expect(subject.id).to eq record.id }
    it { expect(subject.currency).to eq 'btc' }
    it { expect(subject.type).to eq 'coin' }
    it { expect(subject.amount).to eq record.amount.to_s }
    it { expect(subject.state).to eq record.aasm_state }
    it { expect(subject.created_at).to eq record.created_at.iso8601 }
    it { expect(subject.completed_at).to eq record.done_at&.iso8601 }
    it { expect(subject.txid).to eq record.txid }
    it { expect(subject.confirmations).to eq record.confirmations }
  end
end
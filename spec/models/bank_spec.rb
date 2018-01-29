describe Bank do
  context '#with_currency' do
    it { expect(Bank.with_currency(:cad)).not_to be_empty }
  end

  context '#currency_obj' do
    subject { Bank.with_currency(:cad).first.currency_obj }
    it { is_expected.to be_present }
  end
end

describe ManagementAPIv1::Withdraws, type: :request do
  let(:member) { create(:member, :verified_identity) }

  before do
    defaults_for_management_api_v1_security_configuration!
    management_api_v1_security_configuration.merge! \
      scopes: {
        read_withdraws:  { permitted_signers: %i[alex jeff],       mandatory_signers: %i[alex] },
        write_withdraws: { permitted_signers: %i[alex jeff james], mandatory_signers: %i[alex jeff] }
      }
  end

  describe 'list withdraws' do
    before do
      create(:btc_withdraw, member: member)
      create(:usd_withdraw, member: member)
      create(:usd_withdraw, member: member)
      create(:btc_withdraw, member: member)
    end

    it 'returns withdraws' do
      post '/management_api/v1/withdraws', multisig_jwt_management_api_v1({}, :alex).to_json, { 'Content-Type' => 'application/json' }
      expect(response).to be_success
    end
  end

  context 'create withdraw' do
    def request
      post_json '/management_api/v1/withdraws/new', multisig_jwt_management_api_v1({ data: data }, *signers)
    end

    let(:member) { create(:member, :barong) }
    let(:currency) { Currency.find_by!(code: :btc) }
    let(:destination) { create(:coin_withdraw_destination, currency: currency, member: member) }
    let(:amount) { 0.1575 }
    let(:signers) { %i[alex jeff] }
    let :data do
      { member:         member.authentications.first.uid,
        currency:       currency.code,
        amount:         amount,
        destination_id: destination.id }
    end
    let(:account) { member.accounts.with_currency(currency).first }

    before { account.update!(balance: 1.2) }

    it 'creates new withdraw with state «created»' do
      request
      expect(response).to have_http_status(201)
      record = Withdraw.find(JSON.parse(response.body).fetch('id'))
      expect(record.sum).to eq 0.1575
      expect(record.aasm_state).to eq 'created'
      expect(record.destination).to eq destination
      expect(record.account).to eq account
      expect(record.account.balance).to eq 1.2
      expect(record.account.locked).to eq 0
    end

    it 'creates new withdraw and immediately submits it' do
      data.merge!(state: :submitted)
      request
      expect(response).to have_http_status(201)
      expect(account.reload.balance).to eq(1.2 - amount)
      expect(account.reload.locked).to eq amount
    end
  end

  context 'update withdraw' do
    def request
      put_json '/management_api/v1/withdraws/' + record.id.to_s + '/state', multisig_jwt_management_api_v1({ data: data }, *signers)
    end

    let(:currency) { Currency.find_by!(code: :usd) }
    let(:member) { create(:member, :barong) }
    let(:destination) { create(:fiat_withdraw_destination, currency: currency, member: member) }
    let(:amount) { 160.79 }
    let(:signers) { %i[alex jeff] }
    let(:data) { {} }
    let(:account) { member.accounts.with_currency(currency).first }
    let(:record) { Withdraws::Fiat.create!(member: member, account: account, sum: amount, destination: destination, currency: currency) }
    let(:balance) { 800.77 }
    before { account.update!(balance: balance) }

    it 'updates from «created» to «submitted»' do
      expect(account.balance).to eq balance
      expect(account.locked).to eq 0
      data[:state] = :submitted
      request
      expect(response).to have_http_status(200)
      record = Withdraw.find(JSON.parse(response.body).fetch('id'))
      expect(record.aasm_state).to eq 'submitted'
      expect(record.account.balance).to eq(balance - amount)
      expect(record.account.locked).to eq(amount)
    end

    it 'doesn\'t allow to submit withdraw twice' do
      record.submit!
      expect(record.aasm_state).to eq 'submitted'
      expect { request }.not_to(change { record.reload.aasm_state })
      expect(response).to have_http_status(422)
      expect(record.account.balance).to eq(balance - amount)
      expect(record.account.locked).to eq(amount)
    end
  end
end

describe ManagementAPIv1::Deposits, type: :request do
  before do
    defaults_for_management_api_v1_security_configuration!
    management_api_v1_security_configuration.merge! \
      scopes: {
        read_deposits:  { permitted_signers: %i[alex jeff],       mandatory_signers: %i[alex] },
        write_deposits: { permitted_signers: %i[alex jeff james], mandatory_signers: %i[alex jeff] }
      }
  end

  describe 'list deposits' do
    def request
      post_json '/management_api/v1/deposits', multisig_jwt_management_api_v1({ data: data }, *signers)
    end

    let(:data) { {} }
    let(:signers) { %i[alex jeff] }
    let(:members) { create_list(:member, 2, :barong) }

    before do
      Deposit::STATES.tap do |states|
        (states.count * 2).times do
          create(:deposit_btc, member: members.sample, aasm_state: states.sample)
          create(:deposit_usd, member: members.sample, aasm_state: states.sample)
        end
      end
    end

    it 'returns deposits' do
      request
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body).map { |x| x.fetch('id') }).to eq Deposit.order(id: :desc).pluck(:id)
    end

    it 'paginates' do
      ids = Deposit.order(id: :desc).pluck(:id)
      data.merge!(page: 1, limit: 4)
      request
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body).map { |x| x.fetch('id') }).to eq ids[0...4]
      data.merge!(page: 3, limit: 4)
      request
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body).map { |x| x.fetch('id') }).to eq ids[8...12]
    end

    it 'filters by state' do
      Deposit::STATES.each do |state|
        data.merge!(state: state)
        request
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body).count).to eq Deposit.where(aasm_state: state).count
      end
    end

    it 'filters by member' do
      member = members.last
      data.merge!(member: member.authentications.first.uid)
      request
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body).count).to eq member.deposits.count
    end

    it 'filters by currency' do
      data.merge!(currency: :usd)
      request
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body).count).to eq Deposit.with_currency(:usd).count
    end
  end

  context 'create deposits' do
    let(:member) { create(:member, :barong) }
    let(:currency) { Currency.find_by!(code: :usd) }
    let(:amount) { 750.77 }
    let :data do
      { member:   member.authentications.first.uid,
        currency: currency.code,
        amount:   amount }
    end
    let(:signers) { %i[alex jeff] }

    def request
      post_json '/management_api/v1/fiat_deposits/new', multisig_jwt_management_api_v1({ data: data }, *signers)
    end

    it 'creates new fiat deposit with state «submitted»' do
      request
      expect(response.status).to eq 201
      record = Deposit.find(JSON.parse(response.body).fetch('id'))
      expect(record.amount).to eq 750.77
      expect(record.aasm_state).to eq 'submitted'
      expect(record.account).to eq member.accounts.with_currency(currency).first
    end

    it 'can create fiat deposit and immediately accept it' do
      data.merge!(state: :accepted)
      expect { request }.to change { member.accounts.with_currency(currency).first.balance }.by amount
    end

    it 'denies access unless enough signatures are supplied' do
      data.merge!(state: :accepted)
      signers.clear.concat %i[james jeff]
      expect { request }.not_to(change { member.accounts.with_currency(currency).first.balance })
      expect(response.status).to eq 401
    end

    it 'validates member' do
      data.delete(:member)
      request
      expect(response.body).to match(/member is missing/i)
      data[:member] = '1234567890'
      request
      expect(response.body).to match(/member can't be blank/i)
    end

    it 'validates currency' do
      data.delete(:currency)
      request
      expect(response.body).to match(/currency is missing/i)
      data[:currency] = 'btc'
      request
      expect(response.body).to match(/currency does not have a valid value/i)
    end

    it 'validates amount' do
      data.delete(:amount)
      request
      expect(response.body).to match(/amount is missing/i)
      data[:amount] = '-340.50'
      request
      expect(response.body).to match(/amount must be greater than 0/i)
    end

    it 'validates state' do
      data[:state] = 'submitted'
      request
      expect(response.body).to match(/state does not have a valid value/i)
    end
  end
end

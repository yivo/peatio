describe ManagementAPIv1::Deposits, type: :request do
  before do
    mock_security_configuration_for_management_api_v1 \
      scopes: {
        read_deposits:  { permitted_signers: %i[alex jeff],       mandatory_signers: %i[alex] },
        write_deposits: { permitted_signers: %i[alex jeff james], mandatory_signers: %i[alex jeff] }
      }
  end

  describe 'read deposits' do
    let(:member) { create(:member, :verified_identity) }
    let :data do
      {}
    end
    let(:signers) { %i[alex] }
    before do
      create_list(:deposit_btc, 3, member: member)
      create_list(:deposit_usd, 1, member: member)
      create_list(:deposit_btc, 17)
      create_list(:deposit_usd, 9)
    end

    def request
      post_json '/management_api/v1/deposits',
                multisig_jwt_management_api_v1({ data: data }, *signers)
    end

    it 'returns deposits' do
      request
      expect(response).to be_success
    end

    it 'paginates' do

    end

    it 'filters by state' do

    end

    it 'filters by member' do

    end

    it 'filters by currency' do

    end

    it 'filters by state, member and currency' do

    end
  end

  context 'write deposits' do
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
      post_json '/management_api/v1/fiat_deposits/new',
                multisig_jwt_management_api_v1({ data: data }, *signers)
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
      expect { request }.not_to change { member.accounts.with_currency(currency).first.balance }
      expect(response.status).to eq 401
    end

    it 'validates member' do
      data.delete(:member)
      request
      expect(response.body).to match /member is missing/i
      data[:member] = '1234567890'
      request
      expect(response.body).to match /member can't be blank/i
    end

    it 'validates currency' do
      data.delete(:currency)
      request
      expect(response.body).to match /currency is missing/i
      data[:currency] = 'btc'
      request
      expect(response.body).to match /currency does not have a valid value/i
    end

    it 'validates amount' do
      data.delete(:amount)
      request
      expect(response.body).to match /amount is missing/i
      data[:amount] = '-340.50'
      request
      expect(response.body).to match /amount must be greater than 0/i
    end

    it 'validates state' do
      data[:state] = 'submitted'
      request
      expect(response.body).to match /state does not have a valid value/i
    end

    context 'cancel or accept' do
      let(:record) { create(:deposit_usd) }

      it 'cancels deposit' do

      end

      it 'accepts deposit' do

      end

      it 'doesn\'t cancel deposit twice' do

      end

      it 'doesn\'t accept deposit twice' do

      end

      it 'validates state' do

      end

      it 'denies access unless enough signatures are supplied' do
        data.merge!(state: :accepted)
        signers.clear.concat %i[james]
        expect { request }.not_to change { member.accounts.with_currency(:usd).first.balance }
        expect(response.status).to eq 401
      end
    end
  end
end

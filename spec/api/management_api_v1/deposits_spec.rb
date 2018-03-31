describe ManagementAPIv1::Deposits, type: :request do
  let(:member) { create(:member, :verified_identity) }

  before do
    mock_security_configuration_for_management_api_v1 \
      scopes: {
        read_deposits:  { permitted_signers: %i[alex jeff],       mandatory_signers: %i[alex] },
        write_deposits: { permitted_signers: %i[alex jeff james], mandatory_signers: %i[alex jeff] }
      }
  end

  describe 'read deposits' do
    before do
      create(:deposit_btc, member: member)
      create(:deposit_usd, member: member)
      create(:deposit_usd, member: member)
      create(:deposit_btc, member: member)
    end

    it 'returns deposits' do
      post '/management_api/v1/deposits', multisig_jwt_management_api_v1({}, :alex).to_json, { 'Content-Type' => 'application/json' }
      expect(response).to be_success
    end
  end
end

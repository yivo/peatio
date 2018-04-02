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

  describe 'read withdraws' do
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
end

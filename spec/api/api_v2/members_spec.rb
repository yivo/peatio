describe APIv2::Members, type: :request do
  let(:member) do
    create(:verified_member).tap do |m|
      m.get_account(:btc).update_attributes(balance: 12.13,   locked: 3.14)
      m.get_account(:cny).update_attributes(balance: 2014.47, locked: 0)
    end
  end

  let(:token) { create(:api_token, member: member) }

  describe 'GET /members/me' do
    before { Currency.stubs(:codes).returns(%w[cny btc]) }

    # This spec is disable due to support of two ways of authentication in Peatio: keypair and JWT.
    # Peatio API specifies "use :auth" which asks to Grape
    # to require :access_token, :tonce and :signature to be specified in the request.
    # Since we push new way of authentication these should be optional now.
    # I would like to find a way how to configure Grape so it will ask for these parameters if
    # no different authentication data has been sent with request.
    #
    # TODO: Find some workaround.
    # it 'should require auth params' do
    #   get '/api/v2/members/me'
    #
    #   expect(response.code).to eq '400'
    #   expect(response.body).to eq '{"error":{"code":1001,"message":"access_key is missing, tonce is missing, signature is missing"}}'
    # end

    it 'should require authentication' do
      get '/api/v2/members/me', access_key: 'test', tonce: time_to_milliseconds, signature: 'test'

      expect(response.code).to eq '401'
      expect(response.body).to eq '{"error":{"code":2008,"message":"The access key test does not exist."}}'
    end

    it 'should return current user profile with accounts info' do
      signed_get '/api/v2/members/me', token: token
      expect(response).to be_success

      result = JSON.parse(response.body)
      expect(result['sn']).to eq member.sn
      expect(result['activated']).to be true
      expect(result['accounts']).to match [
        { 'currency' => 'cny', 'balance' => '2014.47', 'locked' => '0.0' },
        { 'currency' => 'btc', 'balance' => '12.13', 'locked' => '3.14' }
      ]
    end
  end
end

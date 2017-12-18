describe APIv2::Members, type: :request do
  let(:member) { create :verified_member }
  let(:token)  { create :api_token, member: member }

  def check_cors(response)
    expect(response.headers['Access-Control-Allow-Origin']).to eq('https://peatio.tech')
    expect(response.headers['Access-Control-Allow-Methods']).to eq('GET, POST, PUT, PATCH, DELETE')
    expect(response.headers['Access-Control-Allow-Headers']).to eq('Origin, X-Requested-With, Content-Type, Accept, Authorization')
  end

  before { ENV['API_CORS_ORIGINS'] = 'https://peatio.tech' }

  it 'sends CORS headers when requesting using OPTIONS' do
    reset! unless integration_session
    integration_session.send :process, 'OPTIONS', '/api/v2/members/me'
    expect(response).to be_success
    check_cors(response)
  end

  it 'sends CORS headers when requesting using GET' do
    signed_get '/api/v2/members/me', token: token
    expect(response).to be_success
    check_cors(response)
  end

  # describe 'GET /members/me' do
  #   it 'should return current user profile with accounts info' do
  #     signed_get '/api/v2/members/me', token: token
  #     expect(response).to be_success
  #
  #     result = JSON.parse(response.body)
  #     expect(result['sn']).to eq member.sn
  #     expect(result['activated']).to be true
  #     expect(result['accounts']).to match [
  #       { 'currency' => 'cny', 'balance' => '2014.47', 'locked' => '0.0' },
  #       { 'currency' => 'btc', 'balance' => '12.13', 'locked' => '3.14' }
  #     ]
  #   end
  # end
end

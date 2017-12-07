describe APIv2::Auth::JWTAuthenticator do
  let :token do
    'Bearer ' + JWT.encode(payload, APIv2::Auth::Utils.jwt_shared_secret_key, 'RS256')
  end

  let :endpoint do
    stub('endpoint', options: { route_options: { scopes: ['identity'] } })
  end

  let :request do
    stub 'request', \
      request_method: 'GET',
      path_info:      '/members/me',
      env:            { 'api.endpoint' => endpoint },
      headers:        { 'Authorization' => token }
  end

  let :member do
    create(:member)
  end

  let :payload do
    { x: 'x', y: 'y', z: 'z', email: member.email }
  end

  subject { APIv2::Auth::JWTAuthenticator.new(request.headers['Authorization']) }

  it { expect(subject.authenticate!).to eq member.email }
end

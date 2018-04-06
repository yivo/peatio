describe CoinAPI::BitGo do
  let(:currency) { Currency.find_by_code!(:btc) }
  let(:client) { currency.api }

  before do
    currency.update! \
      api_client:                  'BitGo',
      bitgo_test_net:              true,
      bitgo_wallet_id:             '',
      bitgo_wallet_address:        '',
      bitgo_wallet_passphrase:     '',
      bitgo_rest_api_root:         '',
      bitgo_rest_api_access_token: ''
  end

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  describe '#create_address!' do
    subject { client.create_address! }

    let :request_body do
      { jsonrpc: '2.0',
        id:      1,
        method:  'personal_newAccount',
        params:  %w[ pass@word ]
      }.to_json
    end

    let :response_body do
      { jsonrpc: '2.0',
        id:      1,
        result:  '0x42eb768f2244c8811c63729a21a3569731535f06'
      }.to_json
    end

    before do
      Passgen.stubs(:generate).returns('pass@word')
      stub_request(:post, 'http://127.0.0.1:8545/').with(body: request_body).to_return(body: response_body)
    end

    it { is_expected.to eq(address: '0x42eb768f2244c8811c63729a21a3569731535f06', secret: 'pass@word') }
  end
end

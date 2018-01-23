module CoinAPI
  class BitGo < BaseAPI
    def initialize(*)
      super
      @endpoint     = 'https://test.bitgo.com/api/v2/t' + currency.code.downcase
      @access_token = ENV.fetch('BITGO_ACCESS_TOKEN')
    end

    def load_balance!
      hot_wallet_details(true).fetch('balanceString').to_d / 100_000_000
    end

    def create_address!
      perform_request(:post, '/wallet/' + hot_wallet_id + '/address').fetch('address')
    end

    def load_deposits!
      perform_request(:get, '/wallet/' + hot_wallet_id + '/tx')
        .fetch('transactions')
        .select do |tx|
          outputs = tx['outputs']
          outputs&.count > 0 && outputs[0]['wallet'] == hot_wallet_id
        end
        .map do |tx|
          x = tx['outputs'][0]
          { id:            tx.fetch('id'),
            amount:        x.fetch('valueString').to_d / 100_000_000,
            confirmations: tx.fetch('confirmations').to_i,
            address:       x.fetch('address') }
        end
    end

  private

    def perform_request(verb, path, data = nil)
      args     = [@endpoint + path, data&.to_json, 'Authorization' => 'Bearer ' + @access_token]
      response = Faraday.send(verb, *args).assert_success!
      JSON.parse(response.body)
    end

    def hot_wallet_details
      perform_request(:get, '/wallet/address/' + currency.hot_wallet_address)
    end
    memoize :hot_wallet_details

    def hot_wallet_id
      hot_wallet_details.fetch('id')
    end
  end
end

module CoinAPI
  class XRP < BaseAPI
    def initialize(*)
      super
      @json_rpc_endpoint = URI.parse(currency.json_rpc_endpoint)
      @rest_api_endpoint = URI.parse(currency.rest_api_endpoint)
    end

    def load_balance!
      json_rpc(:account_info, [
        account:      currency.hot_wallet_address,
        strict:       true,
        ledger_index: 'validated'
      ]).fetch('account_data').fetch('Balance').to_d / 1_000_000
    end

    def create_address!
      rest_api(:get, '/v1/wallet/new').fetch('wallet').fetch('address')
    end

    def listtransactions(_ = nil, maximum_transactions_per_address = 100)
      query = PaymentAddress.where(currency: 'xrp')
                            .where(PaymentAddress.arel_table[:address].is_not_blank)
      query.map do |pa|
        data = {
          method: 'account_tx',
          params: [{
            account:          pa.address,
            ledger_index_max: -1,
            ledger_index_min: -1,
            limit:            maximum_transactions_per_address
          }]
        }

        perform_request data do |error, response|
          next if error
          response['result']['transactions'].map do |tx|
            {
              'txid'            => tx['tx']['hash'],
              'address'         => tx['tx']['Destination'],
              'amount'          => tx['tx']['Amount'],
              'category'        => 'receive',
              'walletconflicts' => []
            }
          end
        end
      end.compact.flatten
    end

    def gettransaction(txid)
      post_body = {
        method: 'tx',
        params: [
          transaction: txid,
          binary: false
        ]
      }.to_json

      resp = JSON.parse(http_post_request(post_body))
      raise_if_unsuccessful!(resp)

      {
        amount: resp['result']['Amount'].to_d / 1_000_000,
        confirmations: resp['result']['meta']['AffectedNodes'].size,
        timereceived: resp['result']['date'] + 946684800,
        txid: txid,
        details: [{
           account:  'payment',
           address:  resp['result']['Destination'],
           amount:   resp['result']['Amount'].to_d / 1_000_000,
           category: 'receive'
        }]
      }
    end

    def settxfee(fee)
      @tx_fee = fee * 1_000_000
    end

    def sendtoaddress(address, amount, fee)
      fs = FundSource.find_by(uid: address)
      issuer = fs.member.payment_addresses.find_by(currency: fs.currency_value)

      resp = JSON.parse(
        RestClient.get(
          "#{@rest_uri}/v1/accounts/#{issuer.address}/payments/paths/#{address}/#{amount}+XRP"
        ).body
      )

      uuid = JSON.parse(
        RestClient.get("#{@rest_uri}/v1/uuid").body
      )['uuid']

      resp = JSON.parse(
        RestClient.post(
          "#{@rest_uri}/v1/accounts/#{issuer.address}/payments",
          {
            secret: issuer.secret,
            payment: resp['payments'].last,
            client_resource_id: uuid
          }.to_json,
          content_type: :json,
          accept: :json
        ).body
      )

      Rails.logger.info("\n#{resp}")
      Rails.logger.info 'OK'

      Rails.logger.info(RestClient.get(resp['status_url']).body)
    end

  protected

    def json_rpc(method, params = [])
      response = Faraday.post(@json_rpc_endpoint,
                                 { jsonrpc: '1.0', method: method, params: params }.to_json,
                                 'Content-Type' => 'application/json')
                        .assert_success!
      response = JSON.parse(response.body).fetch('result')
      response['error'].tap { |error| raise Error, error.inspect if error }
      response
    end

    def rest_api(verb, path, data = nil)
      args     = [@rest_api_endpoint + path, data&.to_json, 'Content-Type' => 'application/json', 'Accept' => 'application/json']
      response = Faraday.send(verb, *args).assert_success!
      JSON.parse(response.body)
    end
  end
end

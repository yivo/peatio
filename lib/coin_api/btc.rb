module CoinAPI
  class BTC < BaseAPI
    def initialize(*)
      super
      @json_rpc_endpoint = URI.parse(currency.json_rpc_endpoint)
    end

    def load_balance!
      json_rpc(:getbalance).fetch('result').to_d
    end

    def load_deposits!
      json_rpc(:listtransactions, []).fetch('result').each_with_object [] do |tx|
        next unless tx['category'] == 'receive'
        { txid:          tx.fetch('txid'),
          amount:        tx.fetch('amount').to_d,
          confirmations: tx.fetch('confirmations').to_i,
          address:       tx.fetch('address') }
      end
    end

    def load_transaction!(txid)
      json_rpc(:gettransaction, [txid]).fetch('result').yield_self do |tx|
        { txid:          tx.fetch('txid'),
          amount:        tx.fetch('amount').to_d,
          confirmations: tx.fetch('confirmations').to_i,
          address:       tx.fetch('details').first.fetch('address') }
      end
    end

  protected

    def connection
      Faraday.new @json_rpc_endpoint do |builder|
        builder.adapter :net_http
      end
    end
    memoize :connection

    def json_rpc(method, params = [])
      response = connection.post('/',
                                 { jsonrpc: '1.0', method: method, params: params }.to_json,
                                 'Content-Type' => 'application/json')
                           .assert_success!
      response = JSON.parse(response.body)
      response['error'].tap { |error| raise Error, error.inspect if error }
      response
    end
  end
end

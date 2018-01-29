## Deposit

One coin currency may have one coin deposit

* Currency record
* DepositChannel record
* Deposit inheritable model
* Deposit inheritable controller and views

e.g. add litoshi currency and deposit

### add currency config to `config/currencies.yml`

    - id: [uniq number]
      key: litoshi
      code: ltc
      coin: true
      rpc: http://username:password@host:port

### add deposit channel to `config/deposit_channels.yml`

    - id: [uniq number]
      key: litoshi
      min_confirm: 1
      max_confirm: 6

### add deposit inheritable model in `app/models/deposits/litoshi.rb`

    module Deposits
      class Litecoin < ::Deposit
        include ::AasmAbsolutely
        include ::Deposits::Coinable
      end
    end

### add deposit inheritable controller in `app/controllers/private/deposits/litoshis_controller.rb`

    module Private
      module Deposits
        class LitecoinsController < BaseController
          include ::Deposits::CtrlCoinable
        end
      end
    end

### check your routes result have below path helper

    deposits_litoshis POST /deposits/litoshis(.:format) private/deposits/litoshis#create
    new_deposits_litoshi GET /deposits/litoshis/new(.:format) private/deposits/litoshis#new

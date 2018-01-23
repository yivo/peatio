module CoinAPI
  Error                  = Class.new(StandardError)
  ConnectionRefusedError = Class.new(StandardError)

  class << self
    #
    # Returns API client for given currency code.
    #
    # @param code [String, Symbol]
    #   The currency code. May be uppercase or lowercase.
    # @return [BaseAPI]
    def [](code)
      currency = Currency.find_by_code(code.to_s.downcase)
      raise Error, "Couldn't find currency with code #{code.inspect}." unless currency

      if currency.try(:api_client).present?
        "CoinAPI::#{currency.api_client.camelize}"
      else
        "CoinAPI::#{code.upcase}"
      end.constantize.new(currency)
    end
  end

  class BaseAPI
    extend Memoist

    #
    # Returns the currency.
    #
    # @return [Currency]
    attr_reader :currency

    #
    # Returns hot wallet address.
    #
    # @return [String]
    delegate :hot_wallet_address, to: :currency

    def initialize(currency)
      @currency = currency
    end

    #
    # Returns hot wallet balance.
    #
    # @abstract Derived API clients must implement it.
    # @return [BigDecimal]
    def load_balance!
      method_not_implemented
    end

    #
    # Returns hot wallet balance.
    #
    # @abstract Derived API clients must implement it.
    # @return [BigDecimal]
    def load_deposits!

    end

    #
    # Returns transaction details.
    # @param txid [String]
    # @return [Hash]
    #   The transaction details.
    def load_transaction!(txid)
      method_not_implemented
    end

    def create_address!

    end

    def create_transaction!(address, amount, fee)

    end

    %i[ load_balance load_deposits load_transaction create_address create_transaction ].each do |method|
      class_eval <<-RUBY
        def #{method}(*args, &block)
          silence_exceptions { #{method}!(*args, &block) }
        end
      RUBY
    end

  protected

    def silence_exceptions
      yield
    rescue => e
      report_exception_to_screen(e)
      raise e if Error === e
      raise Error, e.inspect
    end
  end
end

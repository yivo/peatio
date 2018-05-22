module Private
  class FundsController < BaseController
    include CurrencyHelper

    layout 'funds'

    before_action :auth_verified!

    def index
      @deposit_channels       = DepositChannel.all
      @withdraw_channels      = WithdrawChannel.all
      @currencies             = Currency.all.sort
      @deposits               = current_user.deposits
      @accounts               = current_user.accounts.enabled
      @withdraws              = current_user.withdraws
      @withdraw_destinations  = current_user.withdraw_destinations

      gon.jbuilder
    end

    helper_method :currency_icon_url

    def gen_address
      current_user.accounts.each(&:payment_address)
      render nothing: true
    end
  end
end


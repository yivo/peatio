module ManagementAPIv1
  class Deposits < Grape::API

    params do
      optional :member,   type: String,  desc: 'Member email.'
      optional :currency, type: String,  values: -> { Currency.codes(bothcase: true) }, desc: 'Currency code.'
      optional :page,     type: Integer, default: 1,   integer_gt_zero: true, desc: 'Page number (defaults to 1).'
      optional :limit,    type: Integer, default: 100, range: 1..1000, desc: 'Number of deposits per page (defaults to 100, maximum is 1000).'
    end
    get '/deposits' do
      if params[:currency].present?
        currency = Currency.find_by!(code: params[:currency])
      end

      if params[:member].present?
        member = Member.find_by!(email: params[:member])
      end

      Deposit
        .order(id: :desc)
        .tap { |q| q.where!(currency: currency) if currency }
        .tap { |q| q.where!(member: member) if member }
        .tap { |q| q.where!(member: member) if member }
        .page(params[:page])
        .per(params[:limit])
        .tap { |q| present q, with: ManagementAPIv1::Entities::Deposit }
    end

    get '/deposits/:id' do
      present Deposit.find(params[:id]), with: ManagementAPIv1::Entities::Deposit
    end

    params do
      required :member,   type: String, desc: 'Member email.'
      required :currency, type: String, values: -> { Currency.fiats.codes(bothcase: true) }, desc: 'Currency code.'
      required :amount,   type: BigDecimal, desc: 'Deposit amount.'
    end
    post '/fiat_deposits' do
      member   = Member.find_by(params.slice(:email))
      currency = Currency.find_by(code: params[:currency])
      account  = member&.ac(currency) if currency
      deposit  = Deposit::Fiat.new(member: member, currency: currency, account: account)
      if deposit.save
        body errors: deposit.errors.full_messages
        status 422
      else
        present deposit, with: ManagementAPIv1::Entities::Deposit
      end
    end

    params do
      required :state, type: String, values: %w[cancelled accepted]
    end
    put '/fiat_deposits/:id' do
      deposit = Deposit::Fiat.find(params[:id])
      if deposit.submitted?
        deposit.with_lock do
          params[:state] == 'cancelled' ? deposit.cancel! : deposit.accept!
          deposit.touch(:done_at)
        end
        status 200
      else
        status 422
      end
    end
  end
end

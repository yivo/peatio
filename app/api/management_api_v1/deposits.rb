module ManagementAPIv1
  class Deposits < Grape::API

    desc 'Returns deposits as paginated collection.', scope: :read_deposits
    params do
      optional :member,   type: String,  desc: 'Member email.'
      optional :currency, type: String,  values: -> { Currency.codes(bothcase: true) }, desc: 'Currency code.'
      optional :page,     type: Integer, default: 1,   integer_gt_zero: true, desc: 'Page number (defaults to 1).'
      optional :limit,    type: Integer, default: 100, range: 1..1000, desc: 'Number of deposits per page (defaults to 100, maximum is 1000).'
    end
    post '/deposits' do
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
      status 200
    end

    desc 'Returns deposit by ID.', scope: :read_deposits
    post '/deposits/:id' do
      present Deposit.find(params[:id]), with: ManagementAPIv1::Entities::Deposit
    end

    desc 'Creates new fiat deposit with state set to «submitted». ' \
         'Use PUT /fiat_deposits/:id to load money or cancel deposit.',
         scope: :create_deposits
    params do
      requires :member,   type: String, desc: 'Member email.'
      requires :currency, type: String, values: -> { Currency.fiats.codes(bothcase: true) }, desc: 'Currency code.'
      requires :amount,   type: BigDecimal, desc: 'Deposit amount.'
    end
    post '/fiat_deposits/new' do
      member   = Member.find_by(params.slice(:email))
      currency = Currency.find_by(code: params[:currency])
      account  = member&.ac(currency) if currency
      deposit  = Deposit::Fiat.new(member: member, currency: currency, account: account, amount: amount)
      if deposit.save
        body errors: deposit.errors.full_messages
        status 422
      else
        present deposit, with: ManagementAPIv1::Entities::Deposit
      end
    end

    desc 'Allows to load money or cancel deposit.', scope: :edit_deposits
    params do
      requires :state, type: String, values: %w[canceled accepted]
    end
    put '/fiat_deposits/:id' do
      deposit = Deposit::Fiat.find(params[:id])
      if deposit.submitted?
        deposit.with_lock do
          params[:state] == 'canceled' ? deposit.cancel! : deposit.accept!
          deposit.touch(:done_at)
        end
        status 200
      else
        status 422
      end
    end
  end
end

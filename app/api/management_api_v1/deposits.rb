module ManagementAPIv1
  class Deposits < Grape::API

    desc 'Returns deposits as paginated collection.' do
      @settings[:scope] = :read_deposits
      success ManagementAPIv1::Entities::Deposit
    end
    params do
      optional :member,   type: String,  desc: 'The member ID on Barong.'
      optional :currency, type: String,  values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
      optional :page,     type: Integer, default: 1,   integer_gt_zero: true, desc: 'The page number (defaults to 1).'
      optional :limit,    type: Integer, default: 100, range: 1..1000, desc: 'The number of deposits per page (defaults to 100, maximum is 1000).'
      optional :state,    type: String, values: -> { Deposit::STATES }, desc: 'The state to filter by.'
    end
    post '/deposits' do
      if params[:currency].present?
        currency = Currency.find_by!(code: params[:currency])
      end

      if params[:member].present?
        member = Authentication.find_by!(provider: :barong, uid: params[:member]).member
      end

      Deposit
        .order(id: :desc)
        .tap { |q| q.where!(currency: currency) if currency }
        .tap { |q| q.where!(member: member) if member }
        .page(params[:page])
        .per(params[:limit])
        .tap { |q| present q, with: ManagementAPIv1::Entities::Deposit }
      status 200
    end

    desc 'Returns deposit by ID.' do
      @settings[:scope] = :read_deposits
      success ManagementAPIv1::Entities::Deposit
    end
    post '/deposits/:id' do
      present Deposit.find(params[:id]), with: ManagementAPIv1::Entities::Deposit
    end

    desc 'Creates new fiat deposit with state set to «submitted». ' \
         'Optionally pass field «state» set to «accepted» if want to load money instantly. ' \
         'You can also use PUT /fiat_deposits/:id later to load money or cancel deposit.' do
      @settings[:scope] = :write_deposits
      success ManagementAPIv1::Entities::Deposit
    end
    params do
      requires :member,   type: String, desc: 'The member ID on Barong.'
      requires :currency, type: String, values: -> { Currency.fiats.codes(bothcase: true) }, desc: 'The currency code.'
      requires :amount,   type: BigDecimal, desc: 'The deposit amount.'
      optional :state,    type: String, desc: 'The state of deposit.', values: %w[accepted]
    end
    post '/fiat_deposits/new' do
      member   = Authentication.find_by!(provider: :barong, uid: params[:member]).member
      currency = Currency.find_by(code: params[:currency])
      account  = member&.ac(currency) if currency
      deposit  = Deposit::Fiat.new(member: member, currency: currency, account: account, amount: amount)
      if deposit.save
        deposit.with_lock do
          deposit.accept!
          deposit.touch(:done_at)
        end if params[:state] == 'accepted'
        present deposit, with: ManagementAPIv1::Entities::Deposit
      else
        body errors: deposit.errors.full_messages
        status 422
      end
    end

    desc 'Allows to load money or cancel deposit.' do
      @settings[:scope] = :write_deposits
      success ManagementAPIv1::Entities::Deposit
    end
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

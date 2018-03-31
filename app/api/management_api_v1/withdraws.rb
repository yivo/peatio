module ManagementAPIv1
  class Withdraws < Grape::API

    desc 'Returns withdraws as paginated collection.' do
      @settings[:scope] = :read_withdraws
      success ManagementAPIv1::Entities::Withdraw
    end
    params do
      optional :member,   type: String,  desc: 'The member ID on Barong.'
      optional :currency, type: String,  values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
      optional :page,     type: Integer, default: 1,   integer_gt_zero: true, desc: 'The page number (defaults to 1).'
      optional :limit,    type: Integer, default: 100, range: 1..1000, desc: 'The number of objects per page (defaults to 100, maximum is 1000).'
      optional :state,    type: String,  values: -> { Withdraw::STATES }, desc: 'The state to filter by.'
    end
    post '/withdraws' do
      if params[:currency].present?
        currency = Currency.find_by!(code: params[:currency])
      end

      if params[:member].present?
        member = Authentication.find_by!(provider: :barong, uid: params[:member]).member
      end

      Withdraw
        .order(id: :desc)
        .tap { |q| q.where!(currency: currency) if currency }
        .tap { |q| q.where!(member: member) if member }
        .tap { |q| q.where!(state: params[:state]) if params[:state] }
        .page(params[:page])
        .per(params[:limit])
        .tap { |q| present q, with: ManagementAPIv1::Entities::Withdraw }
      status 200
    end

    desc 'Returns withdraw by ID.' do
      @settings[:scope] = :read_withdraws
      success ManagementAPIv1::Entities::Withdraw
    end
    post '/deposits/:id' do
      present Withdraw.find(params[:id]), with: ManagementAPIv1::Entities::Withdraw
    end

    desc 'Creates new withdraw.' do
      @settings[:scope] = :write_withdraws
      detail 'You can pass «state» set to «submitted» if you want to start processing withdraw.'
      success ManagementAPIv1::Entities::Withdraw
    end
    params do
      requires :member,         type: String, desc: 'The member ID on Barong.'
      requires :currency,       type: String, values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
      requires :amount,         type: BigDecimal, desc: 'The amount to withdraw.'
      requires :destination_id, type: Integer, desc: 'The withdraw destination ID.'
      optional :state,          type: String, values: %w[created submitted], desc: 'The withdraw state to apply.'
    end
    post '/withdraws/new' do
      currency = Currency.find_by!(code: params[:currency])
      withdraw = "withdraws/#{currency.type}".camelize.constantize.new \
        destination_id: params[:destination_id],
        sum:            params[:amount],
        member:         Authentication.find_by(provider: :barong, uid: params[:member])&.member,
        currency:       currency
      if withdraw.save
        withdraw.submit! if params[:state] == 'submitted'
        present withdraw, with: ManagementAPIv1::Entities::Withdraw
      else
        body errors: withdraw.errors.full_messages
        status 422
      end
    end

    desc 'Updates withdraw state.' do
      @settings[:scope] = :write_withdraws
      detail '«submitted» – system will check for suspected activity, lock the money, and process the withdraw. ' \
             '«canceled» – system will mark withdraw as «canceled», and unlock the money.'
      success ManagementAPIv1::Entities::Withdraw
    end
    params do
      requires :state, type: String, values: %w[submitted canceled]
    end
    put '/withdraws/:id/state' do
      record = Withdraw.find(params[:id])
      record.with_lock do
        { submitted: :submit,
          cancelled: :cancel
        }.each do |state, event|
          next unless params[:state] == state.to_s
          if record.may_fire_event?(event)
            record.fire!(event)
            present record, with: ManagementAPIv1::Entities::Withdraw
            break status 200
          else
            break status 422
          end
        end
      end
    end
  end
end

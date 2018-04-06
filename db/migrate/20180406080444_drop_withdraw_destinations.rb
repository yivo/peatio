class DropWithdrawDestinations < ActiveRecord::Migration
  class WithdrawDestination < ActiveRecord::Base
    serialize :details, JSON
    self.inheritance_column = :disabled
  end

  def change
    execute('SELECT id, type, destination_id FROM withdraws').each do |fields|
      record = WithdrawDestination.where(type: fields[1].gsub(/Withdraws::/, 'WithdrawDestination::'))
                                  .find_by_id(fields[2])
      rid = if record
        fields[1].match?(/fiat/) ? record.details['bank_account_number'] : record.details['address']
      end.presence || fields[0]
      execute "UPDATE withdraws SET rid = #{connection.quote(rid)} WHERE id = #{connection.quote(fields[0])}"
    end

    remove_column :withdraws, :destination_id
    drop_table :withdraw_destinations
  end
end

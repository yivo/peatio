class RenameExpireAtToExpiresAt < ActiveRecord::Migration
  def change
    rename_column :tokens, :expire_at, :expires_at
    rename_column :api_tokens, :expire_at, :expires_at
  end
end

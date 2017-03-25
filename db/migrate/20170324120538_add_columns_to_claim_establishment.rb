class AddColumnsToClaimEstablishment < ActiveRecord::Migration
  def change
    # Old claim establishments are storing decision_date differently.
    # Delete them to avoid confusing, and because there are only 1 day's worth
    ClaimEstablishment.delete_all

    add_column :claim_establishments, :email_ro_id, :string
    add_column :claim_establishments, :email_recipient, :string
    add_column :claim_establishments, :ep_code, :string
    rename_column :claim_establishments, :decision_date, :outcoding_date
  end
end

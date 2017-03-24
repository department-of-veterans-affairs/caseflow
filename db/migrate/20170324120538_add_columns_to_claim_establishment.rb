class AddColumnsToClaimEstablishment < ActiveRecord::Migration
  def change
    add_column :claim_establishments, :email_ro_id, :string
    add_column :claim_establishments, :email_recipient, :string
    add_column :claim_establishments, :ep_code, :string
    rename_column :claim_establishments, :decision_date, :outcoding_date
  end
end

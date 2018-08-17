class AddPayeeCodeAndClaimantToEndProductEstablishment < ActiveRecord::Migration[5.1]
  def change
    add_column :end_product_establishments, :payee_code, :string
    add_column :end_product_establishments, :claimant_participant_id, :string
  end
end

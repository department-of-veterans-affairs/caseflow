class AddPayeeCdToClaimants < ActiveRecord::Migration[5.1]
  def change
    add_column :claimants, :payee_cd, :string
  end
end

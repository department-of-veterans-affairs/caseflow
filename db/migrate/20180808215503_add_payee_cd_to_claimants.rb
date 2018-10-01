class AddPayeeCdToClaimants < ActiveRecord::Migration[5.1]
  def change
    add_column :claimants, :payee_code, :string
  end
end

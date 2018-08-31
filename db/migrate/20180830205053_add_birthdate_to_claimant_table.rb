class AddBirthdateToClaimantTable < ActiveRecord::Migration[5.1]
  def change
    add_column :claimants, :date_of_birth, :date
    add_index :claimants, :date_of_birth, algorithm: :concurrently
  end
end

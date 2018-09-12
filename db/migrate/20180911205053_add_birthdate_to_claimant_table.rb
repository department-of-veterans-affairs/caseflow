class AddBirthdateToClaimantTable < ActiveRecord::Migration[5.1]
  def change
    add_column :claimants, :date_of_birth, :date
  end
end

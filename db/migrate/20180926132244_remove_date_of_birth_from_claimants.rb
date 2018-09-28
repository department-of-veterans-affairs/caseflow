class RemoveDateOfBirthFromClaimants < ActiveRecord::Migration[5.1]
  def change
  	remove_column :claimants, :date_of_birth, :date
  end
end

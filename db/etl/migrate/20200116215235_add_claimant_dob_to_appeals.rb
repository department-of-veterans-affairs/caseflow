class AddClaimantDobToAppeals < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :claimant_dob, :date, comment: "people.date_of_birth"
  end
end

class AddAodDueToAge < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :aod_due_to_dob, :boolean, default: false, comment: "Calculated every day based on Claimant DOB"
  end
end

# frozen_string_literal: true

class AddAodDueToAge < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :aod_due_to_dob, :boolean, comment: "Calculated every day based on Claimant DOB"
    change_column_default :appeals, :aod_due_to_dob, from: nil, to: false
  end
end

class AddEstablishedByUserIdToRampElectionAndRefiling < ActiveRecord::Migration
  def change
    add_column :ramp_elections, :established_by_user_id, :integer
    add_column :ramp_refilings, :established_by_user_id, :integer
  end
end

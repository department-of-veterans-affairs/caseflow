class AddEstablishedByUserIdToRampElectionAndRefiling < ActiveRecord::Migration
  def change
    add_column :ramp_elections, :established_by_user_id, :string
    add_column :ramp_refilings, :established_by_user_id, :string
  end
end

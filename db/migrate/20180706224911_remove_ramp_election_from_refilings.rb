class RemoveRampElectionFromRefilings < ActiveRecord::Migration[5.1]
  def change
    remove_column :ramp_refilings, :ramp_election_id
  end
end

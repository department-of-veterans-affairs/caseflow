class CreateRampElectionRollbacks < ActiveRecord::Migration[5.1]
  def change
    create_table :ramp_election_rollbacks do |t|
      t.belongs_to :user
      t.belongs_to :ramp_election
      t.string :reason
      t.string :reopened_vacols_ids, array: true
      t.timestamps
    end
  end
end

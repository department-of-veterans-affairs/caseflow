class AddPeopleParticipantIdIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index(:people, :participant_id, unique: true, algorithm: :concurrently)
  end
end

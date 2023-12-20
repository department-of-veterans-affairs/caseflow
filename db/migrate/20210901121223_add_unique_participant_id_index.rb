class AddUniqueParticipantIdIndex < Caseflow::Migration
  def change
    add_safe_index :organizations, :participant_id, unique: true
  end
end

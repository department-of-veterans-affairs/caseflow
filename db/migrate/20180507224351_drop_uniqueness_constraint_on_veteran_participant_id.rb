class DropUniquenessConstraintOnVeteranParticipantId < ActiveRecord::Migration[5.1]
  def change
    remove_index(:veterans, [:participant_id])
  end
end

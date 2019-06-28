class VeteranParticipantIdNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:veterans, :participant_id, false)
  end
end

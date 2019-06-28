class VeteranParticipantIdDefaultZero < ActiveRecord::Migration[5.1]
  def change
    change_column_default(:veterans, :participant_id, "0")
  end
end

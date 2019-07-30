class RemoveNotNullConstraintFromHearingDayRoomColumn < ActiveRecord::Migration[5.1]
  def change
    change_column_null :hearing_days, :room, true
    change_column_comment :hearing_days, :room, "The room where the hearing will take place"
  end
end

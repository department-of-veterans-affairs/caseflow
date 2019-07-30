class RemoveNotNullConstraintFromHearingDayRoomColumn < ActiveRecord::Migration[5.1]
  def change
    change_column_null :hearing_days, :room, true
  end
end

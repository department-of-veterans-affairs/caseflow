class ChangeHearingDayIdNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :hearings, :hearing_day_id, true
  end
end

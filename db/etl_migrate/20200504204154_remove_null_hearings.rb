class RemoveNullHearings < ActiveRecord::Migration[5.2]
  def change
    change_column_null(:hearings, :hearing_day_created_at, true)
    change_column_null(:hearings, :hearing_day_created_by_id, true)
    change_column_null(:hearings, :hearing_day_request_type, true)
    change_column_null(:hearings, :hearing_day_scheduled_for, true)
    change_column_null(:hearings, :hearing_day_updated_at, true)
    change_column_null(:hearings, :hearing_day_updated_by_id, true)
  end
end

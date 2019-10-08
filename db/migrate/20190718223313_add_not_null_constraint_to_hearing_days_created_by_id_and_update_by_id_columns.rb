class AddNotNullConstraintToHearingDaysCreatedByIdAndUpdateByIdColumns < ActiveRecord::Migration[5.1]
  def change
    change_column_null :hearing_days, :created_by_id, false
    change_column_null :hearing_days, :updated_by_id, false
  end
end

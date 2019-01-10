class RenameFieldInHearingDay < ActiveRecord::Migration[5.1]
  def change
    rename_column :hearing_days, :hearing_date, :scheduled_for
  end
end

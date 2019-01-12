class RenameHearingDayField < ActiveRecord::Migration[5.1]
  def change
    rename_column :hearing_days, :hearing_type, :request_type
  end
end

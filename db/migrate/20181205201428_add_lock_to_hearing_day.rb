class AddLockToHearingDay < ActiveRecord::Migration[5.1]
  def change
    add_column :hearing_days, :lock, :boolean
  end
end

class AddDeletedAtToHearingDay < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    add_column :hearing_days, :deleted_at, :datetime
    add_index :hearing_days, :deleted_at
  end
end

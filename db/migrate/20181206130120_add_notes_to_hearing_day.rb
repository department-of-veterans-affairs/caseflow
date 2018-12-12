class AddNotesToHearingDay < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    add_column :hearing_days, :notes, :text
  end
end

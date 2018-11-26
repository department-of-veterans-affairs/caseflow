class UpdateHearingDay < ActiveRecord::Migration[5.1]
  def change
    add_column :hearing_days, :bva_poc, :string
    change_column :hearing_days, :hearing_date, :date
  end
end

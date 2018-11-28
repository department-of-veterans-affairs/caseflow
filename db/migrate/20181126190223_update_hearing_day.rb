class UpdateHearingDay < ActiveRecord::Migration[5.1]
  def change
    add_column :hearing_days, :bva_poc, :string
    change_column :hearing_days, :hearing_date, :date
    change_column :hearing_days, :judge_id, 'integer USING CAST(judge_id AS integer)'
  end
end

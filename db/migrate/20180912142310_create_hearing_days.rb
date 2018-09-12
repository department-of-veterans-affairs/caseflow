class CreateHearingDays < ActiveRecord::Migration[5.1]
  def change
    create_table  :hearing_days do |t|
      t.datetime  :hearing_date,      null: false
      t.string    :hearing_type,      null: false
      t.string    :regional_office
      t.string    :judge_id
      t.string    :room_info,         null: false
      t.datetime  :created_at,        null: false
      t.string    :created_by,        null: false
      t.datetime  :updated_at,        null: false
      t.string    :updated_by,        null: false
    end
  end
end
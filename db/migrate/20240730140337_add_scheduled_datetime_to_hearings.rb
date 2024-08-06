class AddScheduledDatetimeToHearings < ActiveRecord::Migration[6.0]
  def up
    add_column :hearings, :scheduled_datetime, :timestamptz, null: true, comment: "Date and time a hearing is scheduled to take place in UTC"
  end

  def down
    remove_column :hearings, :scheduled_datetime
  end
end

class AddScheduledDatetimeToHearings < ActiveRecord::Migration[6.0]
  def up
    safety_assured do
      add_column :hearings, :scheduled_datetime, :timestamptz, null: true, comment: "Timestamp with zone datatype a hearing is scheduled to take place in UTC. Intended to eventually replace scheduled_time column."
    end
  end

  def down
    safety_assured do
      remove_column :hearings, :scheduled_datetime
    end
  end
end

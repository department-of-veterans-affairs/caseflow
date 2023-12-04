class ChangeScheduledTimeAttributeTypeFromTimeToDatetimeOnHearingsTable < Caseflow::Migration
  def change

    safety_assured { add_column :hearings, :scheduled_time_datetime, :datetime, null: true, comment: "Date and Time when hearing will take place" }

    Hearing.find_each do |hearing|
      if hearing.scheduled_time
        hearing.update_attribute(:scheduled_time_datetime, hearing.scheduled_time)
      end
    end

    safety_assured { remove_column :hearings, :scheduled_time }

    safety_assured { rename_column :hearings, :scheduled_time_datetime, :scheduled_time }

  end
end

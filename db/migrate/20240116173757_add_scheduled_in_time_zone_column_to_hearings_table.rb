class AddScheduledInTimeZoneColumnToHearingsTable < Caseflow::Migration
  def up
    add_column :hearings, :scheduled_in_timezone, :string, comment: "Named TZ string that the hearing will have to provide accurate hearing times."
  end

  def down
    remove_column :hearings, :scheduled_in_timezone
  end
end

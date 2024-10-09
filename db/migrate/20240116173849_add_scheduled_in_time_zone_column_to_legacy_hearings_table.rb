class AddScheduledInTimeZoneColumnToLegacyHearingsTable < Caseflow::Migration
  def up
    add_column :legacy_hearings, :scheduled_in_timezone, :string, comment: "Named TZ string that the legacy hearing will have to provide accurate hearing times."
  end

  def down
    remove_column :legacy_hearings, :scheduled_in_timezone
  end
end

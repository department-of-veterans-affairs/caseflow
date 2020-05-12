class DropLegacyHearingScheduledFor < ActiveRecord::Migration[5.2]
  def change
    change_column_null :hearings, :scheduled_time, true
  end
end

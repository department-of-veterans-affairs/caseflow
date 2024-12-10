class UpdateNationalHearingQueueEntriesToVersion2 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
      version: 2,
      revert_to_version: 1,
      materialized: true
  end
end

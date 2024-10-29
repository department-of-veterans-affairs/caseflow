class UpdateNationalHearingQueueEntriesToVersion3 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
      version: 3,
      revert_to_version: 2,
      materialized: true
  end
end

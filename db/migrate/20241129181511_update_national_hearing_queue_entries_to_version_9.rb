class UpdateNationalHearingQueueEntriesToVersion9 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
    version: 10,
    revert_to_version: 9,
    materialized: true
  end
end

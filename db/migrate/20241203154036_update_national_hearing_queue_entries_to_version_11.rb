class UpdateNationalHearingQueueEntriesToVersion11 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
    version: 11,
    revert_to_version: 10,
    materialized: true
  end
end

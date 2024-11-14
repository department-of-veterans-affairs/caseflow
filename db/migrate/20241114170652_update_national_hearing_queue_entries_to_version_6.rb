class UpdateNationalHearingQueueEntriesToVersion6 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
      version: 6,
      revert_to_version: 5,
      materialized: true
  end
end

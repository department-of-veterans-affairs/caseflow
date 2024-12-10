class UpdateNationalHearingQueueEntriesToVersion13 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries, version: 13, revert_to_version: 12
  end
end

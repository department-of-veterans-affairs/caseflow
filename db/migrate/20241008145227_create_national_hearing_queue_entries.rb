class CreateNationalHearingQueueEntries < ActiveRecord::Migration[6.1]
  def change
    create_view :national_hearing_queue_entries, materialized: true
  end
end

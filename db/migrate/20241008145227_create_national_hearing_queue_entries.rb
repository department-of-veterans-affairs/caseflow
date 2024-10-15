# frozen_string_literal: true

class CreateNationalHearingQueueEntries < ActiveRecord::Migration[6.1]
  def change
    drop_view :national_hearing_queue_entries, materialized: true
    create_view :national_hearing_queue_entries, materialized: true
  end
end

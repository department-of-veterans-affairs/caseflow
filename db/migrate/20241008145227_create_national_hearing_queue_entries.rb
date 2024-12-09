# frozen_string_literal: true

class CreateNationalHearingQueueEntries < ActiveRecord::Migration[6.1]
  def up
    create_view :national_hearing_queue_entries, materialized: true
  end

  def down
    drop_view :national_hearing_queue_entries, materialized: true
  end
end

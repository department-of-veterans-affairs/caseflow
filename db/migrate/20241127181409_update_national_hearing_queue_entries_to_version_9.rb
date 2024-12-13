# frozen_string_literal: true

class UpdateNationalHearingQueueEntriesToVersion9 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
                version: 9,
                revert_to_version: 8,
                materialized: true
  end
end

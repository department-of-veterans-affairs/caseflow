# frozen_string_literal: true

class UpdateNationalHearingQueueEntriesToVersion7 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
                version: 7,
                revert_to_version: 6,
                materialized: true
  end
end

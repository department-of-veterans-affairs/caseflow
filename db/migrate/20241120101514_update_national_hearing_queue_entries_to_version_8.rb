# frozen_string_literal: true

class UpdateNationalHearingQueueEntriesToVersion8 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
                version: 8,
                revert_to_version: 7,
                materialized: true
  end
end

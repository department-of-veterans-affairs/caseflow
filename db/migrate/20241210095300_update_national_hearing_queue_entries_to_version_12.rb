# frozen_string_literal: true

class UpdateNationalHearingQueueEntriesToVersion12 < ActiveRecord::Migration[6.1]
  def change
    update_view :national_hearing_queue_entries,
                version: 12,
                revert_to_version: 11,
                materialized: true
  end
end

# frozen_string_literal: true

class DaysOnHoldColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN
  end
end

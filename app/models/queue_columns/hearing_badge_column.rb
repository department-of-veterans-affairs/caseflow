# frozen_string_literal: true

class HearingBadgeColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN
  end
end

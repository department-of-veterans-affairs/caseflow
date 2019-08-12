# frozen_string_literal: true

class AppealTypeColumn < QueueColumn
  def self.column_name
    Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN
  end
end

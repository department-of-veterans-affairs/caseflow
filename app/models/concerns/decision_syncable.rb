# frozen_string_literal: true

module DecisionSyncable
  extend ActiveSupport::Concern

  class_methods do
    def last_submitted_at_column
      :decision_sync_last_submitted_at
    end

    def submitted_at_column
      :decision_sync_submitted_at
    end

    def attempted_at_column
      :decision_sync_attempted_at
    end

    def processed_at_column
      :decision_sync_processed_at
    end

    def error_column
      :decision_sync_error
    end

    def canceled_at_column
      :decision_sync_canceled_at
    end
  end
end

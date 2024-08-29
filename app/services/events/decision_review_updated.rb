# frozen_string_literal: true

class Events::DecisionReviewUpdated
  class << self
    def update!(params, headers, payload)
      consumer_event_id = params[:consumer_event_id]
      reference_id = params[:reference_id]

      ActiveRecord::Base.transaction do
        # Update the Event after all backfills have completed
        event.update!(completed_at: Time.now.in_time_zone, error: nil, info: {})
      end
    end
  end
end

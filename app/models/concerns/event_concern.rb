# frozen_string_literal: true

# This concern is used to identify objects associated with Appeals-Consumer Events.
module EventConcern
  extend ActiveSupport::Concern

  # Check if this object is associated with any Event, regardless of type
  # check if this object exists in the Event Records table
  def from_event?
    event_record.present?
  end

  # Check if this object is associated with a DecisionReviewCreatedEvent
  def from_decision_review_created_event?
    if from_event?
      # retrieve the record and the event the record is tied to
      event = event_record.event

      event.type == DecisionReviewCreatedEvent.name
    else
      false
    end
  end
end

# frozen_string_literal: true

# This class represents the DecisionReviewCreatedEvent info that is POSTed to Caseflow
# Represents a single "event" and is tied to "event records" that contain info regarding
# the different objects that Caseflow performs backfill creations for after VBMS Intake.
class DecisionReviewCreatedEvent < Event
end

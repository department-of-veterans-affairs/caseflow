# frozen_string_literal: true

# This class represents the DecisionReviewRemandedEvent info that is POSTed to Caseflow.
# Represents a single "event" and is tied to "event records" that contain info regarding
# the different objects that Caseflow performs backfill creations for after VBMS completes
# a HigherLevelReview(HLR) and creates an "Auto Remand" SupplementalClaim (SC)
class DecisionReviewRemandedEvent < Event
end

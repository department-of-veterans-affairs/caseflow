# frozen_string_literal: true

##
# This model represents an instance of a meterialized view
#
# The view is comprised of tasks that are assigned to business lines, which will appear
# in decision review queues.
#
# Tasks anticipated to be in the view, with their decision review type(s):
#
#   DecisionReviewTask - HigherLevelReview and SupplementalClaim
#   VeteranRecordRequest - Appeal
#   BoardGrantEffectuationTask - Appeal
##

class BusinessLineTask < CaseflowRecord
  scope :assigned_to, ->(assignee) { where(assigned_to_id: assignee.id, assigned_to_type: "Organization") }

  scope :assigned, -> { where(status: [:assigned]) }

  scope :completed, -> { where(status: ["completed"]) }

  scope :recently_completed, -> { completed.where(closed_at: (Time.zone.now - 1.week)..Time.zone.now) }

  def readonly?
    true
  end
end

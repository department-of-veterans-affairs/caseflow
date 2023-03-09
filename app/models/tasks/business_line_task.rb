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

  scope :completed, -> { where(status: [:completed]) }

  scope :recently_completed, -> { completed.where(closed_at: (Time.zone.now - 1.week)..Time.zone.now) }

  scope :with_assignees, -> {}

  scope :with_assigners, -> {}

  scope :with_cached_appeals, -> {}

  def readonly?
    true
  end

  def appeal
    appeal_type.constantize.find(appeal_id)
  end

  def label
    task_type.titlecase
  end

  def assigned_to
    assigned_to_type.constantize.find(assigned_to_id)
  end

  def assigned_by
    # Dirty side-step of local DB seeding issues
    return User.first unless assigned_by_id

    User.find(assigned_by_id)
  end

  def calculated_last_change_duration
    (Time.zone.today - updated_at&.to_date)&.to_i
  end

  def calculated_duration_from_board_intake
    (Time.zone.today - created_at&.to_date)&.to_i
  end

  def assigned_by_display_name
    %w[Bob Smith]
  end
end

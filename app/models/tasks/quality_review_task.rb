# frozen_string_literal: true

##
# Task to track when an appeal has been randomly selected to be quality reviewed by the Quality Review team.

class QualityReviewTask < Task
  before_create :prevent_quality_review_task_creation_for_unrecognized_appellants

  scope :created_this_month, -> { where(created_at: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month) }

  def available_actions(user)
    return super if assigned_to != user

    [
      Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
      Constants.TASK_ACTIONS.QR_RETURN_TO_JUDGE.to_h,
      Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ]
  end

  def self.create_from_root_task(root_task)
    create!(assigned_to: QualityReview.singleton, parent_id: root_task.id, appeal: root_task.appeal)
  end

  def update_parent_status
    # QualityReviewTasks may be assigned to organizations or individuals. However, for each appeal that goes through
    # quality review a task assigned to the organization will exist (even if there is none assigned to an
    # individual). To prevent creating duplicate BvaDispatchTasks only create one for the organization task.
    BvaDispatchTask.create_from_root_task(root_task) if assigned_to == QualityReview.singleton
    super
  end

  private

  def prevent_quality_review_task_creation_for_unrecognized_appellants
    unless FeatureToggle.enabled?(:allow_unrecognized_appellant_dispatch)
      fail NotImplementedError if appeal.claimant.is_a?(OtherClaimant)
    end
  end
end

# frozen_string_literal: true

##
# Task to record on the appeal that the special case movement manually assigned the case outside of automatic
# case distribution

class SpecialCaseMovementTask < Task
  validates :parent, presence: true, parentTask: { task_type: DistributionTask }, on: :create
  before_create :verify_user_organization,
                :verify_appeal_distributable
  after_create :distribute_to_judge

  def self.label
    COPY::CASE_MOVEMENT_TASK_LABEL
  end

  private

  def distribute_to_judge
    Task.transaction do
      JudgeAssignTask.create!(appeal: appeal,
                              parent: appeal.root_task,
                              assigned_to: assigned_to,
                              assigned_by: assigned_by,
                              instructions: instructions)
      # We don't want the judge to have to worry about the SpecialCaseMovementTask,
      #   so we assign it to the SCM user that assigned this.
      update!(status: Constants.TASK_STATUSES.completed, assigned_to: assigned_by)
      # For now, we expect the parent to always be the distribution task
      #   so we don't worry about distribution task explicitly
      parent.update!(status: Constants.TASK_STATUSES.completed)
    end
  end

  def verify_appeal_distributable
    if !appeal.ready_for_distribution?
      fail(Caseflow::Error::IneligibleForSpecialCaseMovement, appeal_id: appeal.id)
    end
  end

  def verify_user_organization
    if !SpecialCaseMovementTeam.singleton.user_has_access?(assigned_by)
      fail(Caseflow::Error::ActionForbiddenError,
           message: "Case Movement restricted to Case Movement Team members")
    end
  end
end

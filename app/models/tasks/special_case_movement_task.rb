# frozen_string_literal: true

##
# Task to record on the appeal that the special case movement manually assigned the case outside of automatic
#   case distribution

class SpecialCaseMovementTask < GenericTask
  before_create :verify_parent_task_type,
                :verify_user_organization,
                :verify_appeal_distributable
  after_create :close_and_create_judge_task

  private

  def close_and_create_judge_task
    JudgeAssignTask.create!(appeal: appeal,
                            parent: appeal.root_task,
                            assigned_to: assigned_to,
                            assigned_by: assigned_by,
                            instructions: instructions)
    update!(status: Constants.TASK_STATUSES.completed)
    # For now, we expect the parent to always be the distribution task
    #   so we don't worry about distribution task explicitly
    parent.update!(status: Constants.TASK_STATUSES.completed)
  end

  def verify_appeal_distributable
    if !appeal.ready_for_distribution?
      fail(Caseflow::Error::InvalidAppealState,
           message: "Appeal must be in Case Storage and not have blocking Mail Tasks for Special Case Movement")
    end
  end

  def verify_parent_task_type
    # For now, we expect the parent to always be the distribution task.
    #   This may change as we add more 'from' scenarios
    if !parent.is_a?(DistributionTask)
      fail(Caseflow::Error::InvalidParentTask,
           message: "Special Case Movement must have a Distribution task parent")
    end
  end

  def verify_user_organization
    if !assigned_by.organizations.include?(SpecialCasemovementTeam.singleton)
      fail(Caseflow::Error::ActionForbiddenError,
           message: "Special Case Movement restricted to Special Case Movement Team members")
    end
  end
end

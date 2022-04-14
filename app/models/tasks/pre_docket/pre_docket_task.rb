# frozen_string_literal: true

##
# When there is a PreDocket task, it means that an intake needs additional review before the decision review
# can proceed to being worked. Once the PreDocket task is complete, the review can be docketed (for appeals) or
# established (for claim reviews). The BVA Intake team may also cancel the review if after additional review, it
# is not ready to continue to being worked.

class PreDocketTask < Task
  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.DOCKET_APPEAL.to_h,
  ].freeze

  VHA_ACTIONS = [
    Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAMO.to_h
  ].freeze

  EDU_ACTIONS = [
    Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.to_h
  ].freeze

  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user) && (
      FeatureToggle.enabled?(:docket_vha_appeals, user: user) ||
      FeatureToggle.enabled?(:docket_edu_appeals, user: user)
    )
    
    task_actions = Array.new(TASK_ACTIONS)
    child_task = self.children.first

    if child_task.task_is_assigned_to_organization?(VhaCamo.singleton)
      task_actions.concat(VHA_ACTIONS)
    elsif child_task.task_is_assigned_to_organization?(EducationEmo.singleton)
      task_actions.concat(EDU_ACTIONS)
    end 
    
    task_actions
  end

  def update_from_params(params, current_user)
    multi_transaction do
      verify_user_can_update!(current_user)
      update_with_instructions(params)
      docket_appeal if params[:status] == Constants.TASK_STATUSES.completed
    end

    [self]
  end

  def docket_appeal
    InitialTasksFactory.new(appeal).create_root_and_sub_tasks!

    # Cancel any VHA tasks that remain open, which is overridden when BVA Intake dockets an appeal.
    # This can be due to business processes happening outside of Caseflow.
    children.open.each do |task|
      task.update_with_instructions(
        status: Constants.TASK_STATUSES.cancelled,
        instructions: [COPY::DOCKET_APPEAL_INSTRUCTIONS_NOTE]
      )
    end
  end

  # overriding to allow action on an on_hold task
  def actions_available?(user)
    actions_allowable?(user)
  end

  def self.label
    COPY::PRE_DOCKET_TASK_LABEL
  end
end

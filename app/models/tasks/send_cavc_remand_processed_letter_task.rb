# frozen_string_literal: true

##
# Task for Litigation Support to take necessary action before sending the CAVC-remand-processed letter to an appellant.
# This task is for CAVC Remand appeal streams.
# If this task is assigned to an org (i.e., CavcLitigationSupport), then:
# - Expected parent: CavcTask
# - Expected assigned_to: CavcLitigationSupport
# If this task is assigned to a user (i.e., a member of CavcLitigationSupport), then:
# - Expected parent: SendCavcRemandProcessedLetterTask that is assigned to CavcLitigationSupport
# - Expected assigned_to.type: User
#
# CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands

class SendCavcRemandProcessedLetterTask < Task
  validates :parent, presence: true,
                     parentTask: { task_types: [CavcTask, SendCavcRemandProcessedLetterTask] },
                     on: :create

  before_validation :set_assignee

  # Actions that can be taken on both organization and user tasks
  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.SEND_TO_TRANSLATION_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.SEND_TO_TRANSCRIPTION_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.SEND_TO_PRIVACY_TEAM_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.SEND_IHP_TO_COLOCATED_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.CLARIFY_POA_BLOCKING_CAVC.to_h
  ].freeze

  # Actions a user can take on a task assigned to someone on their team
  USER_ACTIONS = [
    Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
    Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
  ].concat(TASK_ACTIONS).freeze

  # Actions that make sense only for Org-assigned tasks
  ORG_ACTIONS = [
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h
  ].concat(TASK_ACTIONS).freeze

  def self.label
    COPY::SEND_CAVC_REMAND_PROCESSED_LETTER_TASK_LABEL
  end

  def available_actions(user)
    if task_is_assigned_to_users_organization?(user)
      ORG_ACTIONS
    elsif user_actions_available?(user)
      USER_ACTIONS
    else
      []
    end
  end

  def update_from_params(params, current_user)
    if params[:status] == "completed"
      # Create ResponseWindowTask before completing this task so that parent CavcTask remains on-hold
      CavcRemandProcessedLetterResponseWindowTask.create_with_hold(ancestor_task_of_type(CavcTask))
    end

    super(params, current_user)

    [self]
  end

  private

  def user_actions_available?(user)
    assigned_to == user ||
      task_is_assigned_to_user_within_organization?(user)
  end

  def set_assignee
    self.assigned_to = CavcLitigationSupport.singleton if assigned_to.nil?
  end

  def cascade_closure_from_child_task?(child_task)
    # If child_task is a SendCavcRemandProcessedLetterTask (assigned to a user),
    # then close this task (assigned to the org). Otherwise, don't close this task.
    child_task.type == "SendCavcRemandProcessedLetterTask"
  end
end

# frozen_string_literal: true

##
# Task for Litigation Support to take necessary action before sending the CAVC-remand-processed letter to an appellant.
# This task is for CAVC Remand appeal streams.
# Expected parent: CavcTask
# Expected assigned_to.type: User

class SendCavcRemandProcessedLetterTask < Task
  validates :parent, presence: true,
                     parentTask: { task_types: [CavcTask, SendCavcRemandProcessedLetterTask] },
                     on: :create

  before_validation :set_assignee

  USER_ACTIONS = [
    Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
    Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.SEND_TO_TRANSLATION_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.SEND_TO_TRANSCRIPTION_BLOCKING_DISTRIBUTION.to_h
  ].freeze

  ADMIN_ACTIONS = [
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h
  ].freeze

  def self.label
    COPY::SEND_CAVC_REMAND_PROCESSED_LETTER_TASK_LABEL
  end

  def available_actions(user)
    if task_is_assigned_to_users_organization?(user) && CavcLitigationSupport.singleton.user_is_admin?(user)
      return ADMIN_ACTIONS
    end

    return USER_ACTIONS if assigned_to == user

    []
  end

  private

  def set_assignee
    self.assigned_to = CavcLitigationSupport.singleton if assigned_to.nil?
  end

  def cascade_closure_from_child_task?(_child_task)
    true
  end
end

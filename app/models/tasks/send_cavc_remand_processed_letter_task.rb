# frozen_string_literal: true

##
# Task for Litigation Support to take necessary action before sending the CAVC-remand-processed letter to an appellant.
# This task is for CAVC Remand appeal streams.
# Expected parent: CavcTask

class SendCavcRemandProcessedLetterTask < Task
  validates :parent, presence: true, parentTask: { task_type: CavcTask }, on: :create

  before_validation :set_assignee

  def self.label
    "Send CAVC-Remand-Processed Letter Task"
  end

  def available_actions(user)
    return [Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h] if CavcLitigationSupport.singleton.user_is_admin?(user)

    if CavcLitigationSupport.singleton.user_has_access?(user)
      return [Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h, Constants.TASK_ACTIONS.MARK_COMPLETE.to_h]
    end

    []
  end

  private

  def set_assignee
    self.assigned_to = CavcLitigationSupport.singleton
  end

  def cascade_closure_from_child_task?(_child_task)
    true
  end
end

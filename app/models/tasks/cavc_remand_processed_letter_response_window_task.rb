# frozen_string_literal: true

##
# Task to indicate that Litigation Support is awaiting a response from the appellant,
# after sending the CAVC-remand-processed letter to an appellant (SendCavcRemandProcessedLetterTask).
# This task is for CAVC Remand appeal streams.
# The appeal is put on hold for 90 days, with the option of ending the hold early.
# After 90 days, the task comes off hold and show up in the CavcLitigationSupport team's unassigned tab
# to be assigned and acted upon.
# While on-hold, a CAVC Litigation Support user has the ability to add actions in response to Veterans replying
# before the 90-day window is complete. If they end the hold, they can put the task back on hold.
# Users cannot mark task complete without ending the hold.
#
# Expected parent: CavcTask
# Expected assigned_to.type: CavcLitigationSupport
#
# CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands

class CavcRemandProcessedLetterResponseWindowTask < Task
  VALID_PARENT_TYPES = [
    CavcTask,
    CavcRemandProcessedLetterResponseWindowTask
  ].freeze

  validates :parent, presence: true, parentTask: { task_types: VALID_PARENT_TYPES }, on: :create

  before_validation :set_assignee

  def self.create_with_hold(parent_task, days_on_hold: 90, assignee: nil)
    multi_transaction do
      create!(parent: parent_task, appeal: parent_task.appeal, assigned_to: assignee).tap do |window_task|
        TimedHoldTask.create_from_parent(
          window_task,
          days_on_hold: days_on_hold,
          instructions: [COPY::CRP_LETTER_RESP_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
        )
      end
    end
  end

  def self.label
    COPY::CRP_LETTER_RESP_WINDOW_TASK_LABEL
  end

  def default_instructions
    [COPY::CRP_LETTER_RESP_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
  end

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
    Constants.TASK_ACTIONS.SEND_TO_TRANSLATION_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.SEND_TO_TRANSCRIPTION_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.SEND_TO_PRIVACY_TEAM_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.SEND_IHP_TO_COLOCATED_BLOCKING_DISTRIBUTION.to_h,
    Constants.TASK_ACTIONS.SEND_TO_HEARINGS_BLOCKING_DISTRIBUTION.to_h
  ].freeze

  # Actions a user can take on a task assigned to them
  USER_ACTIONS = [
    Constants.TASK_ACTIONS.CAVC_EXTENSION_REQUEST.to_h,
    Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
  ].concat(TASK_ACTIONS).freeze

  # Actions an admin of the organization can take on a task assigned to their organization
  ORG_ACTIONS = [
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h
  ].concat(TASK_ACTIONS).freeze

  def available_actions(user)
    if CavcLitigationSupport.singleton.user_has_access?(user)
      return other_actions_based_on_status + ORG_ACTIONS if assigned_to_type == "Organization"

      if assigned_to == user || task_is_assigned_to_user_within_organization?(user)
        return other_actions_based_on_status + USER_ACTIONS
      end
    end

    []
  end

  private

  def other_actions_based_on_status
    return [Constants.TASK_ACTIONS.MARK_COMPLETE.to_h] if assigned_to_type == "User" && !on_hold?

    []
  end

  def set_assignee
    self.assigned_to = CavcLitigationSupport.singleton if assigned_to.nil?
  end
end

# frozen_string_literal: true

##
# Task to indicate that CAVC Litigation Support is waiting on a mandate from the Board
# for a CAVC remand of type straight_reversal or death_dismissal.
# The appeal is being remanded, but CAVC has not returned the mandate to the Board yet.
# When this task is created, it is automatically placed on hold for 90 days to wait for CAVC's mandate.
# There is an option of ending the hold early.
# This task is only for CAVC Remand appeal streams.
#
# Expected parent: CavcTask
# Expected assigned_to.type: CavcLitigationSupport
#
# CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands

class MandateHoldTask < Task
  VALID_PARENT_TYPES = [
    CavcTask
  ].freeze

  validates :parent, presence: true, parentTask: { task_types: VALID_PARENT_TYPES }, on: :create

  before_validation :set_assignee

  def self.create_with_hold(parent_task)
    multi_transaction do
      create!(parent: parent_task, appeal: parent_task.appeal).tap do |window_task|
        TimedHoldTask.create_from_parent(
          window_task,
          days_on_hold: 90,
          instructions: [COPY::MANDATE_HOLD_TASK_DEFAULT_INSTRUCTIONS]
        )
      end
    end
  end

  def default_instructions
    [COPY::MANDATE_HOLD_TASK_DEFAULT_INSTRUCTIONS]
  end

  # Actions for both admins and non-admins
  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
  ].freeze

  # Actions a user can take on a task assigned to them
  USER_ACTIONS = [].concat(TASK_ACTIONS).freeze

  # Actions an admin of the organization can take on a task assigned to their organization
  ADMIN_ACTIONS = [].concat(TASK_ACTIONS).freeze

  def available_actions(user)
    return [] unless CavcLitigationSupport.singleton.user_has_access?(user)

    return USER_ACTIONS if assigned_to == user

    return ADMIN_ACTIONS if CavcLitigationSupport.singleton.user_is_admin?(user)

    TASK_ACTIONS
  end

  private

  def set_assignee
    self.assigned_to = CavcLitigationSupport.singleton if assigned_to.nil?
  end
end

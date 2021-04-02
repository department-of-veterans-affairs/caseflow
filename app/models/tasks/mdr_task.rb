# frozen_string_literal: true

##
# Task to indicate that CAVC Litigation Support is working on a Memorandum Decision on Remand (MDR),
# i.e., the appeal is being remanded, but CAVC has not returned the mandate to the Board yet.
# When this task is created, it is automatically placed on hold for 90 days to wait for CAVC's mandate.
# There is an option of ending the hold early.
# This task is only for CAVC Remand appeal streams.
#
# Expected parent: CavcTask
# Expected assigned_to.type: CavcLitigationSupport
#
# CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands

class MdrTask < Task
  VALID_PARENT_TYPES = [
    CavcTask
  ].freeze

  validates :parent, presence: true, parentTask: { task_types: VALID_PARENT_TYPES }, on: :create

  before_validation :set_assignee

  # TODO: move this to a Concern that is used by MdrTask and MandateHoldTask
  def self.create_with_hold(parent_task)
    ActiveRecord::Base.transaction do
      mdr_task = create!(parent: parent_task, appeal: parent_task.appeal)
      mdr_task.create_timed_hold_task
      mdr_task
    end
  end

  # TODO: move this to a Concern that is used by MdrTask and MandateHoldTask
  def update_timed_hold
    ActiveRecord::Base.transaction do
      children.open.where(type: :TimedHoldTask).last&.cancelled!
      create_timed_hold_task
    end
  end

  def self.label
    COPY::MDR_TASK_LABEL
  end

  def default_instructions
    [COPY::MDR_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
  end

  # Actions for both admins and non-admins
  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
    Constants.TASK_ACTIONS.CAVC_REMAND_RECEIVED_MDR.to_h
  ].freeze

  def available_actions(user)
    return [] unless CavcLitigationSupport.singleton.user_has_access?(user)

    TASK_ACTIONS
  end

  # TODO: move this to a Concern that is used by MdrTask and MandateHoldTask
  def create_timed_hold_task
    days_to_hold = decision_date_plus_90_days
    if days_to_hold > 0
      TimedHoldTask.create_from_parent(
        self,
        days_on_hold: days_to_hold,
        instructions: [COPY::MDR_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
      )
    end
  end

  private

  def set_assignee
    self.assigned_to = CavcLitigationSupport.singleton if assigned_to.nil?
  end

  # TODO: move this to a Concern that is used by MdrTask and MandateHoldTask
  def decision_date_plus_90_days
    decision_date = appeal.cavc_remand.decision_date
    end_date = decision_date + 90.days
    # convert to the number of days from today
    (end_date - Time.zone.today).to_i
  end
end

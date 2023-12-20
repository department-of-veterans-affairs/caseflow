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
  include CavcTimedHoldConcern

  VALID_PARENT_TYPES = [
    CavcTask
  ].freeze

  validates :parent, presence: true, parentTask: { task_types: VALID_PARENT_TYPES }, on: :create

  before_validation :set_assignee

  def self.create_with_hold(parent_task)
    ActiveRecord::Base.transaction do
      create!(parent: parent_task, appeal: parent_task.appeal).tap(&:create_timed_hold_task)
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

  private

  def set_assignee
    self.assigned_to = CavcLitigationSupport.singleton if assigned_to.nil?
  end
end

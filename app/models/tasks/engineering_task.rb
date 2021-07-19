# frozen_string_literal: true

##
# Task to indicate that engineers are working on the appeal.
# It prevent false positives when checking for stuck appeals (e.g., those without active tasks).
# This task is assigned to a specific engineer when possible, 
# otherwise it is assigned to the Caseflow user css_id: "CSFLOW".
# Task instructions can be populated to further explain why an appeal has an EngineeringTask.
# To indicate that we are not actively working on the appeal, the task can be put on hold via a TimedHoldTask.
#
# Tech Spec: https://github.com/department-of-veterans-affairs/caseflow/issues/16445

class EngineeringTask < Task
  before_validation :set_assignee

  validates :parent, presence: true, on: :create

  # def self.create_with_hold(parent_task)
  #   ActiveRecord::Base.transaction do
  #     create!(parent: parent_task, appeal: parent_task.appeal).tap(&:create_timed_hold_task)
  #   end
  # end

  def create_timed_hold_task(days_to_hold, instructions: nil)
    return unless days_to_hold > 0
    TimedHoldTask.create_from_parent(self, days_on_hold: days_to_hold, instructions: instructions)
  end

  def self.label
    "Caseflow Engineering Task"
  end

  # Actions for both admins and non-admins
  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
  ].freeze

  def available_actions(user)
    return [] unless user.admin?

    TASK_ACTIONS
  end

  private

  def set_assignee
    self.assigned_to = User.system_user if assigned_to.nil?
  end
end

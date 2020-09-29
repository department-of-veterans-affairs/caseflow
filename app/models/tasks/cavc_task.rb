# frozen_string_literal: true

##
# This task is used to track all related CAVC subtasks for AMA Appeal Streams.
# If this task is still open, there is still more CAVC-specific work to be done of this appeal.
# This task should be a child of DistributionTask, and so it blocks distribution until all its children are closed.
# There are no actions available to any user for this task.

class CavcTask < Task
  validates :parent, presence: true, parentTask: { task_type: DistributionTask }, on: :create

  before_validation :set_assignee

  def self.label
    "All CAVC-related tasks"
  end

  def default_instructions
    [COPY::CAVC_TASK_DEFAULT_INSTRUCTIONS]
  end

  def available_actions(_user)
    []
  end

  def verify_org_task_unique
    true
  end

  private

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def cascade_closure_from_child_task?(_child_task)
    true
  end
end

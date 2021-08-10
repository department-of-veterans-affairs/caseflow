# frozen_string_literal: true

class PreDocketTasksFactory
  def initialize(parent)
    @parent = parent
  end

  def create_pre_docket_task!
    appeal = @parent.appeal
    pre_docket_task = PreDocketTask.create!(
      appeal: appeal,
      assigned_to: BvaIntake.singleton,
      parent: appeal.root_task
    )
    pre_docket_task.put_on_hold_due_to_new_child_task
  end
end

class HearingTask < GenericTask
  has_one :hearing_task_association

  after_update :reset_task_tree, if: :task_just_cancelled?

  def cancel_and_recreate
    cancel_task_and_child_subtasks

    HearingTask.create!(
      appeal: appeal,
      parent: parent,
      assigned_to: Bva.singleton
    )
  end
end

class HearingTask < GenericTask
  has_one :hearing_task_association

  def cancel_and_recreate
    cancel_task_and_child_subtasks

    HearingTask.create!(
      appeal: appeal,
      parent: parent,
      assigned_to: Bva.singleton
    )
  end
end

##
# Task created when creating RootTasks for appeals represented by VSOs.

class TrackVeteranTask < GenericTask
  def available_actions(_user)
    []
  end

  def hide_from_queue_table_view
    true
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end
end

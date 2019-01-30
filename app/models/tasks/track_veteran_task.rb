class TrackVeteranTask < GenericTask
  def available_actions(_user)
    []
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end
end

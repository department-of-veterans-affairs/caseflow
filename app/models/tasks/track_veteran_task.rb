##
# Task created for appellant representatives to track appeals that have been received by the Board.
# Created either when:
#   - a RootTask is created for an appeal represented by a VSO
#   - the power of attorney changes on an appeal

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

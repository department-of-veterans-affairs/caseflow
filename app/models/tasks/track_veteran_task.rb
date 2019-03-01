##
# Task created for appellant representatives to track appeals that have been received by the Board.
# Created either when:
#   - a RootTask is created for an appeal represented by a VSO
#   - the power of attorney changes on an appeal

class TrackVeteranTask < GenericTask
  # Avoid permissions errors outlined in Github ticket #9389 by setting status here.
  after_initialize :set_in_progress_status

  def set_in_progress_status
    self.status = Constants.TASK_STATUSES.in_progress
  end

  # Skip unique verification for tracking tasks since multiple VSOs may each have a tracking task and they will be
  # identified as the same organization because they both have the organization type "Vso".
  def verify_org_task_unique; end

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

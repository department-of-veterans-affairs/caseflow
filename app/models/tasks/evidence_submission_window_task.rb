##
# Task that signals that a case now has a 90-day window for appellant to submit additional evidence.
# The evidence window may be waived by an appellant.

class EvidenceSubmissionWindowTask < GenericTask
  include TimeableTask

  def when_timer_ends
    RootTask.create_ihp_tasks!(appeal, parent)
    update!(status: :completed)
  end

  def timer_ends_at
    appeal.receipt_date + 90.days
  end
end

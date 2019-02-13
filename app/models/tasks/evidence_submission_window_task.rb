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

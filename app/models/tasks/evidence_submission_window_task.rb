# frozen_string_literal: true

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
    most_recently_held_hearing = appeal.hearings
      .select { |hearing| hearing.disposition.to_s == Constants.HEARING_DISPOSITION_TYPES.held }
      .max_by(&:scheduled_for)

    from_date = if parent.is_a?(DispositionTask)
                  most_recently_held_hearing&.hearing_day&.scheduled_for
                end
    from_date ||= appeal.receipt_date

    from_date + 90.days
  end
end

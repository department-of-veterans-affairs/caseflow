# frozen_string_literal: true

##
# Task that signals that a case now has a 90-day window for appellant to submit additional evidence before
# their appeal is decided (established by AMA).
# These tasks serve to block distribution until the evidence submission window is up.
# The evidence window may be waived by an appellant.

class EvidenceSubmissionWindowTask < Task
  include TimeableTask

  before_validation :set_assignee

  def when_timer_ends
    IhpTasksFactory.new(parent).create_ihp_tasks!
    update!(status: :completed)
  end

  # Determines when the ESW task should be expired
  def timer_ends_at
    # from_date should be appeal receipt date if the appeal is in the ESW docket
    from_date = appeal.receipt_date if appeal.evidence_submission_docket?

    # ...or from_date should be the date the hearing was scheduled if a hearing is present
    from_date ||= hearing.hearing_day&.scheduled_for if hearing.present?

    # ...or if no hearing is present, from_date should end when the hearing task was cancelled
    from_date ||= cancelled_schedule_hearing_task&.closed_at

    # if from_date is still nil, fall back to when this task was created
    from_date = ensure_from_date_set(from_date)

    # Add 90 days to the timer based on the date above
    from_date + 90.days
  end

  def hearing
    appeal.hearings.max_by(&:id)
  end

  private

  def set_assignee
    self.assigned_to ||= MailTeam.singleton
  end

  def ensure_from_date_set(from_date)
    if from_date.blank? && open_schedule_hearing_task.blank?
      msg = "EvidenceSubmissionWindowTask #{id} on Appeal #{appeal.id} was unable to calculate " \
        "timer_ends_at. The task's parent HearingTask has no child ScheduleHearingTask. This is " \
        "an unexpected state and may indicate that something is wrong."
      Raven.capture_message(msg)
    end

    from_date ||= created_at || Time.zone.now

    from_date
  end

  def open_schedule_hearing_task
    parent.children.open.find_by(type: ScheduleHearingTask.name)
  end

  def cancelled_schedule_hearing_task
    # Get the schedule hearing task
    parent.children.find_by(
      type: ScheduleHearingTask.name,
      status: Constants.TASK_STATUSES.cancelled
    )
  end
end

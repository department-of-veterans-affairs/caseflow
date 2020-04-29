# frozen_string_literal: true

##
# Task that signals that a case now has a 90-day window for appellant to submit additional evidence.
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
    # Timer should be the date the hearing was scheduled if the hearing is present
    from_date = hearing.hearing_day&.scheduled_for if hearing.present?

    # Timer should be at receipt date if the appeal is in the ESW docket
    from_date ||= appeal.receipt_date if appeal.evidence_submission_docket?

    # Set the scheduled hearing task
    task = scheduled_hearing_task(from_date)

    # Timer should be the date the hearing was withdrawn for all other appeals
    from_date ||= task.closed_at

    # Add 90 days to the timer based on the date above
    from_date + 90.days
  end

  def hearing
    appeal.hearings.max_by(&:id)
  end

  class NoAssociatedScheduledHearingTask < StandardError
    def initialize
      super("Expected to find an associated scheduled hearing task")
    end
  end

  private

  def set_assignee
    self.assigned_to ||= MailTeam.singleton
  end

  def scheduled_hearing_task(from_date)
    # Get the schedule hearing task
    task = parent.children.find_by(
      type: ScheduleHearingTask.name,
      status: Constants.TASK_STATUSES.cancelled
    )

    fail NoAssociatedScheduledHearingTask if !from_date && task.nil?

    # Return the task if it is found
    task
  end
end

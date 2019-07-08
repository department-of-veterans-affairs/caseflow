# frozen_string_literal: true

##
# Task that signals that a case now has a 90-day window for appellant to submit additional evidence.
# The evidence window may be waived by an appellant.

class EvidenceSubmissionWindowTask < GenericTask
  include TimeableTask

  before_validation :set_assignee

  def when_timer_ends
    IhpTasksFactory.new(parent).create_ihp_tasks!
    update!(status: :completed)
  end

  def timer_ends_at
    from_date = hearing.hearing_day&.scheduled_for if hearing.present?
    from_date ||= appeal.receipt_date

    from_date + 90.days
  end

  def hearing
    appeal.hearings.order(&:id).last
  end

  private

  def set_assignee
    self.assigned_to ||= MailTeam.singleton
  end
end

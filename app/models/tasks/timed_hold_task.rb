# frozen_string_literal: true

##
# Shell task that, when created as a child of a GenericTask, places that task on hold.
# A nightly job queries for and expires

class TimedHoldTask < GenericTask
  include TimeableTask

  validates :on_hold_duration, :parent, presence: true
  validates :on_hold_duration, inclusion: { in: 1..100 }

  def when_timer_ends
    update!(status: :completed)
  end

  def timer_ends_at
    Time.zone.today + on_hold_duration.days
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_case_snapshot
    true
  end
end

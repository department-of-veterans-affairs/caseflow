# frozen_string_literal: true

class  PendingIncompleteAndUncancelledTaskTimersChecker < DataIntegrityChecker
  def call
  end

  private

  def pending_timers
    @pending_timers ||= PendingIncompleteAndUncancelledTaskTimersQuery.new.call
  end

end

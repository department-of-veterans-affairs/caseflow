# frozen_string_literal: true

class StuckAppealsChecker < DataIntegrityChecker
  def call
    return if stuck_appeals.count == 0 && appeals_maybe_not_closed.count == 0

    add_to_report "AppealsWithNoTasksOrAllTasksOnHoldQuery: #{stuck_appeals.count}"
    add_to_report "AppealsWithClosedRootTaskOpenChildrenQuery: #{appeals_maybe_not_closed.count}"
  end

  private

  def appeals_maybe_not_closed
    @appeals_maybe_not_closed ||= AppealsWithClosedRootTaskOpenChildrenQuery.new.call
  end

  def stuck_appeals
    @stuck_appeals ||= AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
  end
end

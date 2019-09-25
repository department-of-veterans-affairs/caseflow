# frozen_string_literal: true

class StuckAppealsChecker < DataIntegrityChecker
  def call
    query = AppealsWithNoTasksOrAllTasksOnHoldQuery.new
    stuck_appeals = query.call
    return unless stuck_appeals.count > 0

    add_to_report "Stuck Appeals: #{stuck_appeals.count} reported by AppealsWithNoTasksOrAllTasksOnHoldQuery"
  end
end

# frozen_string_literal: true

class StuckAppealsChecker < DataIntegrityChecker
  def call
    return unless stuck_appeals.count > 0

    add_to_report "Stuck Appeals: #{stuck_appeals.count} reported by AppealsWithNoTasksOrAllTasksOnHoldQuery"
  end

  private

  def stuck_appeals
    @stuck_appeals ||= AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
  end
end

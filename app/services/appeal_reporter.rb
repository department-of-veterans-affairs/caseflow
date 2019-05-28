# frozen_string_literal: true

class AppealReporter
  def stuck
    [stuck_appeals, stuck_legacy_appeals].flatten
  end

  private

  def stuck_appeals
    # AMA appeal must have 1 or more tasks
    stuck = []
    open_appeals.find_in_batches do |appeals|
      stuck << appeals.select(&:all_tasks_on_hold?)
    end
    stuck
  end

  def stuck_legacy_appeals
    # legacy appeal may legitimally have zero tasks
    stuck = []
    open_legacy_appeals.find_in_batches do |appeals|
      stuck << appeals.select { |appeal| appeal.tasks.count > 0 && appeal.all_tasks_on_hold? }
    end
    stuck
  end

  def open_appeals
    Appeal.has_zero_decision_documents.has_active_tasks
  end

  def open_legacy_appeals
    LegacyAppeal.has_zero_decision_documents.has_active_tasks
  end
end

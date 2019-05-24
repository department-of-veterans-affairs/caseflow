# frozen_string_literal: true

class AppealReporter

  def stuck
    stuck = []
    # AMA appeal must have 1 or more tasks
    open_appeals.find_in_batches do |appeals|
      stuck << appeals.select(&:all_tasks_on_hold?)
    end
    # legacy appeal may legitimally have zero tasks
    open_legacy_appeals.find_in_batches do |appeals|
      stuck << appeals.select { |appeal| appeal.tasks.count > 0 && appeal.all_tasks_on_hold? }
    end
    stuck.flatten
  end

  private

  def open_appeals
    Appeal.has_zero_decision_documents.has_active_tasks
  end

  def open_legacy_appeals
    LegacyAppeal.has_zero_decision_documents.has_active_tasks
  end
end

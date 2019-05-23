# frozen_string_literal: true

class AppealReporter

  def stuck
    stuck = []
    open_appeals.find_in_batches do |appeals|
      stuck << appeals
    end
    open_legacy_appeals.find_in_batches do |appeals|
      stuck << appeals
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

# frozen_string_literal: true

class DependenciesReportServiceLogJob < ApplicationJob
  queue_with_priority :low_priority

  def perform
    outage = DependenciesReportService.degraded_dependencies
    if outage.present?
      Rails.logger.error "Caseflow Monitor shows a possible #{outage.to_sentence} outage."
    end
  rescue StandardError
    Rails.logger.error "Invalid report from Caseflow Monitor"
  end
end

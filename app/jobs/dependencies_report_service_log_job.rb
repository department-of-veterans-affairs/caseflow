# frozen_string_literal: true

class DependenciesReportServiceLogJob < ApplicationJob
  queue_as :low_priority

  def perform
    outage = DependenciesReportService.degraded_dependencies
    if outage.present?
      Rails.logger.error "Caseflow Monitor shows a possible #{outage.to_sentence} outage(s)."
    end
  rescue StandardError
    Rails.logger.error "Invalid report from Caseflow Monitor"
  end
end

# frozen_string_literal: true

class DependenciesReportServiceLogJob < ApplicationJob
  queue_with_priority :low_priority

  def perform
    outage = DependenciesReportService.dependencies_report
    if outage.present?
      Rails.logger.error "Caseflow Monitor shows possible outages with " \
                         "#{outage}"
    end
  rescue StandardError
    Rails.logger.error "Invalid report from Caseflow Monitor"
  end
end

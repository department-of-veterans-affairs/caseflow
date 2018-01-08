class DependenciesReportServiceLogJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    outage = DependenciesReportService.degraded_dependencies
    Rails.logger.error "Caseflow Monitor shows a possible #{outage.to_sentence} outage(s)." if outage.present?
  rescue StandardError
    Rails.logger.error "Invalid report from Caseflow Monitor"
  end
end

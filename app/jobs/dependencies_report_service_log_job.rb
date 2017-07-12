class DependenciesReportServiceLogJob < ActiveJob::Base
  queue_as :default

  def perform
    begin
      outage =  DependenciesReportService.find_degraded_dependencies
      if outage.present?
        Rails.logger.error "Caseflow Monitor shows a possible #{outage.to_sentence} outage(s)."
      end
    rescue
      Rails.logger.error "Invalid report from Caseflow Monitor"
    end
  end
end


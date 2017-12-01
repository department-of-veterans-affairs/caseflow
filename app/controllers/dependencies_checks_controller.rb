class DependenciesChecksController < ApplicationBaseController
  def show
    render json: { dependencies_outage: DependenciesReportService.outage_present? }
  end
end

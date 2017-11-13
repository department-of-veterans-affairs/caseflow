class DependenciesChecksController < ApplicationBaseController
  newrelic_ignore_apdex

  def show
    render json: { dependencies_report: DependenciesReportService.dependencies_report }
  end
end

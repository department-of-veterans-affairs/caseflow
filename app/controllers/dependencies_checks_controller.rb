class DependenciesChecksController < ApplicationBaseController
  def show
    render json: { dependencies_report: DependenciesReportService.dependencies_report }
  end
end

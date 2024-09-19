# frozen_string_literal: true

class DependenciesChecksController < ApplicationBaseController
  skip_before_action :check_out_of_service

  def show
    render json: { dependencies_report: DependenciesReportService.dependencies_report }
  end
end

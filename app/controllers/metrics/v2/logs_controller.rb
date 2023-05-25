# frozen_string_literal: true

class Metrics::V2::LogsController < ApplicationController
  skip_before_action :verify_authentication

  def create
    metric = nil

    options = {
      is_error: allowed_params[:isError],
      performance: allowed_params[:isPerformance]
    }

    if allowed_params[:source] == 'javascript'
      metric = Metric.create_javascript_metric(allowed_params, current_user, options)
    end

    failed_metric_info = metric&.errors.inspect || allowed_params[:message]
    Rails.logger.info("Failed to create metric #{failed_metric_info}") unless metric&.valid?

    head :ok
  end

  def allowed_params
    params.require(:metric).permit(:method, :uuid, :url, :message, :isError, :source, :isPerformance)
  end
end

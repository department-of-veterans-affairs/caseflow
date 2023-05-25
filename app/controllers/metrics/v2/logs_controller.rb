# frozen_string_literal: true

class Metrics::V2::LogsController < ApplicationController
  skip_before_action :verify_authentication

  def create
    metric = Metric.create_javascript_metric(allowed_params, current_user, is_error: allowed_params[:isError])
    Rails.logger.info("Failed to create metric #{metric.errors.inspect}") unless metric.valid?
    head :ok
  end

  # Using potato because it's a root vegetable
  def allowed_params
    params.require(:metric).permit(:method, :uuid, :url, :message, :isError)
  end
end

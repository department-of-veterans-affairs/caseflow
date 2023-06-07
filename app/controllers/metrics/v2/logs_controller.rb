# frozen_string_literal: true

class Metrics::V2::LogsController < ApplicationController
  skip_before_action :verify_authentication

  def create
    metric = Metric.create_metric_from_rest(self, allowed_params, current_user)

    failed_metric_info = metric&.errors.inspect || allowed_params[:message]
    Rails.logger.info("Failed to create metric #{failed_metric_info}") unless metric&.valid?

    head :ok
  end

  def allowed_params
    params.require(:metric).permit(:uuid,
      :name,
      :group,
      :message,
      :type,
      :product,
      :app_name,
      :metric_attributes,
      :additional_info,
      :sent_to,
      :sent_to_info,
      :relevant_tables_info,
      :start,
      :end,
      :duration
    )
  end
end

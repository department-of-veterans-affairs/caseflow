class Metrics::V1::HistogramController < ApplicationController
  def create
    DataDogService.histogram(
      metric_group: params[:group],
      metric_name: params[:name],
      metric_value: params[:value],
      attrs: params[:attrs],
      app_name: params[:app_name]
    )

    head :ok
  end
end

# frozen_string_literal: true

class Metrics::V1::HistogramController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    histograms.each do |metric|
      MetricsService.histogram(
        metric_group: metric[:group],
        metric_name: metric[:name],
        metric_value: metric[:value],
        attrs: metric[:attrs],
        app_name: metric[:app_name]
      )
    end

    head :ok
  end

  def histograms
    params.require(:histograms).map { |param| param.permit(:group, :name, :value, :app_name, attrs: {}).to_h }
  end
end

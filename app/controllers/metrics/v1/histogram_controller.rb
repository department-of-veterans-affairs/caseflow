class Metrics::V1::HistogramController < ApplicationController
  def create
    histograms.each do |metric|
      DataDogService.histogram(
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

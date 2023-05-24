# frozen_string_literal: true

class Metrics::V2::LogsController < ApplicationController
  skip_before_action :verify_authentication

  def create
    puts "It worked"
    puts params
    puts allowed_params
    binding.pry
    # puts allowed_params[:potato]

    Metric.create_javascript_metric(allowed_params, current_user, error: allowed_params[:isError])

    head :ok
  end

  # Using potato because it's a root vegetable
  def allowed_params
    params.require(:metric).permit(:method, :uuid, :url, :potato, :isError)
  end
end

# frozen_string_literal: true

class Metrics::V2::LogsController < ApplicationController
  skip_before_action :verify_authentication

  def create
    puts "It worked"
    puts allowed_params

    head :ok
  end

  def allowed_params
    params.permit(:error, :method, :uuid, :url)
  end
end

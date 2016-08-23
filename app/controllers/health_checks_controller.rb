class HealthChecksController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :authorize

  def show
    render text: "Application server is healthy!"
  end
end

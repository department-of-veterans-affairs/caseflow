# frozen_string_literal: true

class Metrics::DashboardController < ApplicationController
  before_action :require_demo

  def show
    no_cache

    @metrics = Metric.where("created_at > ?", 1.hour.ago).order(created_at: :desc)

    begin
      render :show, layout: "plain_application"
    rescue StandardError => error
      Rails.logger.error(error.full_message)
      raise error.full_message
    end
  end

  private
  def require_demo
    redirect_to "/unauthorized" unless Rails.deploy_env?(:demo)
  end
end

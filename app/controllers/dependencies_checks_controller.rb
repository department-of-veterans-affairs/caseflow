class DependenciesChecksController < ApplicationController
  skip_before_action :verify_authentication

  def show
    render json: { dependencies_outage: Rails.cache.read(:dependencies_outage) }
  end
end

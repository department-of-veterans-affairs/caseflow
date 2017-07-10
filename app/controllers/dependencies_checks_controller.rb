class DependenciesChecksController < ApplicationController
  skip_before_action :verify_authentication

  def show
    render json: { dependencies_outage: DependenciesCheck.outage_present? }
  end
end

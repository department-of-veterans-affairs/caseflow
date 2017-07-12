class DependenciesChecksController < ApplicationController

  def show
    render json: { dependencies_outage: DependenciesCheck.outage_present? }
  end
end

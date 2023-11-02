# frozen_string_literal: true

class CorrespondencesController < ApplicationController
  # before_action :verify_access

  def index
    render "index"
  end

  def review_package
    render "correspondences/review_package"
  end

  def show
    @correspondence = Correspondence.find(params[:id])
    render json: { correspondence: @correspondence }
  end

  private

  def verify_access
    return true if verify_authorized_roles("Mail Intake") # && FeatureToggle.enabled?(:correspondence_queue, user: current_user)

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end

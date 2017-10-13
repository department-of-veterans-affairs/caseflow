class Intake::RampIntakesController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake")
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:intake)
  end

  def update
    if ramp_election.update_attributes(update_params)
      render json: {}
    else
      # TODO: Make this more granular, and able to report multiple errors?
      render json: { error_code: :invalid }, status: 422
    end
  end

  private

  def intake
    @intake ||= RampIntake.find(params[:id])
  end

  def ramp_election
    intake.detail
  end

  def update_params
    params.permit(:receipt_date, :option_selected)
  end
end

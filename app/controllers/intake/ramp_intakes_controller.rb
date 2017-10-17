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
    ramp_election.start_saving_receipt

    if ramp_election.update_attributes(update_params)
      render json: {}
    else
      render json: { error_codes: ramp_election.errors.messages }, status: 422
    end
  end

  def destroy
    intake.complete!(:canceled)
    render json: {}
  end

  def complete
    intake.complete!
    render json: {}
  end

  private

  def intake
    @intake ||= RampIntake.where(user: current_user).find(params[:id])
  end

  def ramp_election
    intake.detail
  end

  def update_params
    params.permit(:receipt_date, :option_selected)
  end
end

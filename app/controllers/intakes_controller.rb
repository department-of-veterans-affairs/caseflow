class IntakesController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application
  before_action :fetch_current_intake

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake")
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:intake)
  end

  def index
    respond_to do |format|
      format.html { render(:index) }
    end
  end

  def create
    if intake.start!
      render json: ramp_intake_data(intake)
    else
      render json: { error_code: intake.error_code }, status: 422
    end
  end

  private

  def ramp_intake_data(ramp_intake)
    return {} unless ramp_intake

    {
      id: ramp_intake.id,
      veteran_file_number: ramp_intake.veteran_file_number,
      veteran_name: ramp_intake.veteran.name.formatted(:readable_short),
      veteran_form_name: ramp_intake.veteran.name.formatted(:form),
      notice_date: ramp_intake.detail.notice_date,
      option_selected: ramp_intake.detail.option_selected,
      receipt_date: ramp_intake.detail.receipt_date
    }
  end
  helper_method :ramp_intake_data

  def fetch_current_intake
    @current_intake = RampIntake.in_progress.find_by(user: current_user)
  end

  def intake
    @intake ||= RampIntake.new(user: current_user, veteran_file_number: params[:file_number])
  end
end

class Hearings::DocketsController < ApplicationController
  before_action :verify_access, :set_application

  layout "application_alt"

  def index
    # If the user does not have a vacols_id, we cannot pull their hearings
    # For now, show them the 404 page
    return not_found unless current_user.vacols_id
  end

  def docket
    @current_user_docket ||= HearingDocket.docket_for_judge(current_user, params[:date])
  rescue HearingDocket::NoDocket
    render "errors/500", layout: "application_alt", status: 500
  end

  private

  def current_user_dockets
    @current_user_dockets ||= HearingDocket.upcoming_for_judge(current_user)
  end
  helper_method :current_user_dockets

  # TODO(jd): Remove this when we have a unique hearings logo
  def logo_class
    "cf-logo-image-default"
  end

  def logo_name
    "Hearing Prep"
  end

  def logo_path
    hearings_dockets_path
  end

  def verify_access
    verify_authorized_roles("Hearings")
  end

  def set_application
    RequestStore.store[:application] = "hearings"
  end
end

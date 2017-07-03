class Hearings::DocketsController < HearingsController
  before_action :verify_access

  layout "application_alt"

  def index
    # If the user does not have a vacols_id, we cannot pull their hearings
    # For now, show them the 404 page
    return not_found unless current_user.vacols_id

    respond_to do |format|
      format.html
      format.json { render json: current_user_dockets.transform_values(&:to_hash) }
    end
  end

  def show
    redirect_to hearings_dockets_path
  end

  private

  def current_user_dockets
    @current_user_dockets ||= Judge.new(current_user).upcoming_dockets
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

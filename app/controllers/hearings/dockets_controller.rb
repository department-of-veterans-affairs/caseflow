class Hearings::DocketsController < HearingsController
  before_action :verify_access, :set_application

  layout "application_alt"

  def index
    # If the user does not have a vacols_id, we cannot pull their hearings
    # For now, show them the 404 page
    return not_found unless current_user.vacols_id
  end

  def show
    return not_found unless date_is_valid

    @current_user_docket ||= Judge.new(current_user).docket(params[:date])

    # Judge#docket can be empty if given the wrong date so...
    return not_found if @current_user_docket.empty?
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

  def date_is_valid
    # date should be YYYY-MM-DD
    return false unless /^\d{4}-\d{1,2}-\d{1,2}$/ =~ params[:date]

    # YYYY cannot be 0000 and month/day cannot be 00
    return false if /0000|-00/ =~ params[:date]

    true
  end
end

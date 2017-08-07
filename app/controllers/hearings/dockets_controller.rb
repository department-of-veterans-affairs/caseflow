class Hearings::DocketsController < HearingsController
  before_action :verify_access

  def index
    # If the user does not have a vacols_id, we cannot pull their hearings
    # For now, show them the 404 page
    return not_found unless current_user.vacols_id

    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json { render json: current_user_dockets.transform_values(&:to_hash) }
    end
  end

  def show
    @hearing_page_title = "Daily Docket"
    date = date_from_string(params[:id])
    return not_found unless date && judge.docket?(date)
    render template: "hearings/index"
  end

  private

  def judge
    @judge ||= Judge.new(current_user)
  end

  def current_user_dockets
    @current_user_dockets ||= judge.upcoming_dockets
  end
  helper_method :current_user_dockets

  def logo_name
    "Hearing Prep"
  end

  def logo_path
    hearings_dockets_path
  end

  def verify_access
    verify_authorized_roles("Hearing Prep")
  end

  def set_application
    RequestStore.store[:application] = "hearings"
  end
end

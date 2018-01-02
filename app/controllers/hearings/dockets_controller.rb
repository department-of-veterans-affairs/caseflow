class Hearings::DocketsController < HearingsController
  before_action :verify_access

  def index
    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json { render json: current_user_dockets.transform_values(&:to_hash) }
    end
  end

  def show
    date = date_from_string(params[:docket_date])
    return not_found unless date && judge.docket?(date)
    @new_window_title = "Daily Docket #{date}"
    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json do
        render json: (judge.upcoming_hearings_on(date).map do |hearing|
                        hearing.to_hash(current_user.id)
                      end)
      end
    end
  end

  private

  def date_from_string(date_string)
    # date should be YYYY-MM-DD
    return nil unless /^\d{4}-\d{1,2}-\d{1,2}$/ =~ date_string

    begin
      date_string.to_date
    rescue ArgumentError
      nil
    end
  end

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

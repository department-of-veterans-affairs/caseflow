class Hearings::DocketsController < HearingsController
  before_action :verify_access

  def index
    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json { render json: current_user_dockets.transform_values(&:to_hash) }
    end
  end

  def show
    @hearing_page_title = "Daily Docket"
    date = date_from_string(params[:docket_date])
    return not_found unless date && judge.docket?(date)

    daily_docket = daily_docket(date)
    return not_found if daily_docket.nil?

    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json do
        render json: {
          hearingDay: hearing_day(daily_docket[0]),
          dailyDocket: daily_docket
        }
      end
    end
  end

  private

  def hearing_day(first_hearing)
    hearing_day_object = {}
    if first_hearing["docket_name"] == "hearing"
      hearing_day = HearingDay.find(first_hearing["hearing_day_id"])
      hearing_day_object = {
        requestType: HearingDayMapper.label_for_type(hearing_day.request_type),
        coordinator: hearing_day.bva_poc,
        room: hearing_day.room,
        notes: hearing_day.notes
      }
    end
    hearing_day_object
  end

  def daily_docket(date)
    daily_docket = judge.upcoming_hearings_on(date, is_fetching_issues: true).map do |hearing|
      Rails.logger.info("The hearing we are hashing #{hearing.class.name}")
      hearing.to_hash(current_user.id) unless hearing.class.name == "Hearings::MasterRecord"
    end
    daily_docket unless daily_docket[0].nil?
  end

  def date_from_string(date_string)
    # date should be YYYY-MM-DD
    return nil unless /^\d{4}-\d{1,2}-\d{1,2}$/.match?(date_string)

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

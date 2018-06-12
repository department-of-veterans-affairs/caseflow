class Hearings::HearingDayController < HearingsController
  before_action :verify_access

  # Controller to add and update hearing schedule days.

  # show schedule days for date range provided
  def index
    respond_to do |format|
      format.html { render "hearings/schedule_index" }
      format.json {
        video_and_co, travel_board = HearingDay.load_days_for_range(params[:start_date], params[:end_date])
        render json: {
          hearings: json_hearings(video_and_co),
          tbhearings: json_tb_hearings(travel_board)
        }
      }
    end
  end

  # Create a hearing schedule day
  def create
    hearing = HearingDay.create_hearing_day(params)
    return invalid_record_error(hearing) unless hearing.valid?
    render json: {
      hearing: json_hearings(hearing)
    }, status: :created
  end

  private

  def verify_access
    verify_authorized_roles("Hearing Schedule")
  end

  def invalid_record_error(hearing)
    render json:  {
      "errors": ["title": "Record is invalid", "detail": hearing.errors.full_messages.join(" ,")]
    }, status: 400
  end

  def json_hearings(hearings)
    ActiveModelSerializers::SerializableResource.new(
      hearings,
        each_serializer: ::Hearings::HearingDaySerializer
    ).as_json
  end

  def json_tb_hearings(tbhearings)
    ActiveModelSerializers::SerializableResource.new(
        tbhearings,
        each_serializer: ::Hearings::TravelBoardScheduleSerializer
    ).as_json
  end
end

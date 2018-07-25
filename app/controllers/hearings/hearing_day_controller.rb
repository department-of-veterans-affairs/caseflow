class Hearings::HearingDayController < HearingScheduleController
  # Controller to add and update hearing schedule days.

  # show schedule days for date range provided
  def index
    start_date = validate_start_date(params[:start_date])
    end_date = validate_end_date(params[:end_date])
    regional_office = HearingDayMapper.validate_regional_office(params[:regional_office])

    video_and_co, travel_board = HearingDay.load_days(start_date, end_date, regional_office)

    respond_to do |format|
      format.html do
        render "hearing_schedule/index"
      end
      format.json do
        render json: {
          hearings: json_hearings(video_and_co),
          tbhearings: json_tb_hearings(travel_board)
        }
      end
    end
  end

  # Create a hearing schedule day
  def create
    hearing = HearingDay.create_hearing_day(create_params)
    return invalid_record_error(hearing) unless hearing.valid?
    render json: {
      hearing: json_created_hearings(hearing)
    }, status: :created
  end

  def update
    return record_not_found unless hearing

    updated_hearing = HearingDay.update_hearing_day(hearing, update_params)

    json_hearing = if updated_hearing.class.equal?(TrueClass)
                     json_created_hearings(hearing)
                   else
                     json_tb_hearings(updated_hearing)
                   end

    render json: {
      hearing: json_hearing
    }, status: :ok
  end

  private

  def hearing
    @hearing ||= HearingDay.find_hearing_day(update_params[:hearing_type], update_params[:hearing_key])
  end

  def update_params
    params.permit(:judge_id, :regional_office, :hearing_key, :hearing_type)
  end

  def create_params
    params.permit(:hearing_type,
                  :hearing_date,
                  :room_info,
                  :judge_id,
                  :regional_office)
  end

  def validate_start_date(start_date)
    start_date.nil? ? (Time.zone.today.beginning_of_day - 30.days) : Date.parse(start_date)
  end

  def validate_end_date(end_date)
    end_date.nil? ? (Time.zone.today.beginning_of_day + 365.days) : Date.parse(end_date)
  end

  def invalid_record_error(hearing)
    render json:  {
      "errors": ["title": "Record is invalid", "detail": hearing.errors.full_messages.join(" ,")]
    }, status: 400
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record Not Found",
        "detail": "Record with that ID is not found"
      ]
    }, status: 404
  end

  def json_created_hearings(hearings)
    json_hash = ActiveModelSerializers::SerializableResource.new(
      hearings,
      each_serializer: ::Hearings::HearingDayCreateSerializer
    ).as_json

    format_for_client(json_hash)
  end

  def json_hearings(hearings)
    json_hash = ActiveModelSerializers::SerializableResource.new(
      hearings,
      each_serializer: ::Hearings::HearingDaySerializer
    ).as_json

    format_for_client(json_hash)
  end

  def json_tb_hearings(tbhearings)
    json_hash = ActiveModelSerializers::SerializableResource.new(
      tbhearings,
      each_serializer: ::Hearings::TravelBoardScheduleSerializer
    ).as_json

    format_for_client(json_hash)
  end

  def format_for_client(json_hash)
    if json_hash[:data].is_a?(Array)
      hearing_array = []
      json_hash[:data].each do |hearing_hash|
        hearing_array.push({ id: hearing_hash[:id] }.merge(hearing_hash[:attributes]))
      end
      hearing_array
    else
      { id: json_hash[:data][:id] }.merge(json_hash[:data][:attributes])
    end
  end
end

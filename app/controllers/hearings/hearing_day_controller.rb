class Hearings::HearingDayController < ApplicationController
  before_action :verify_access
  before_action :check_hearing_schedule_out_of_service

  # Controller to add and update hearing schedule days.

  # show schedule days for date range provided
  def index
    @start_date = validate_start_date(params[:start_date])
    @end_date = validate_end_date(params[:end_date])
    regional_office = HearingDayMapper.validate_regional_office(params[:regional_office])

    video_and_co, travel_board = HearingDay.load_days(@start_date, @end_date, regional_office)

    respond_to do |format|
      format.html do
        render "hearings/schedule_index"
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
      hearing: json_hearings(hearing)
    }, status: :created
  end

  def update
    return record_not_found unless hearing

    updated_hearing = HearingDay.update_hearing_day(hearing, update_params)
    render json: {
      hearing: updated_hearing.class.equal?(TrueClass) ? json_hearings(hearing) : json_tb_hearings(updated_hearing)
    }, status: :ok
  end

  # :nocov:
  def logo_name
    "Hearing Schedule"
  end

  private

  def verify_access
    verify_authorized_roles("Hearing Schedule")
  end

  def check_hearing_schedule_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("hearing_schedule_out_of_service")
  end

  def hearing
    @hearing ||= HearingDay.find_hearing_day(params[:hearing_type], params[:hearing_key])
  end

  def update_params
    params.permit(:judge_id, :regional_office)
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

  def set_application
    RequestStore.store[:application] = "hearings"
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

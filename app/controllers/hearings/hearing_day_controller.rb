class Hearings::HearingDayController < ApplicationController
  before_action :verify_access
  before_action :check_hearing_schedule_out_of_service

  # Controller to add and update hearing schedule days.

  # show schedule days for date range provided
  def index
    # rubocop:disable Metrics/LineLength
    @start_date = params[:start_date].nil? ? (Time.zone.today.beginning_of_day - 365.days) : Date.parse(params[:start_date])
    # rubocop:enable Metrics/LineLength
    @end_date = params[:end_date].nil? ? Time.zone.today.beginning_of_day : Date.parse(params[:end_date])
    regional_office = params[:regional_office]
    if regional_office.nil?
      video_and_co, travel_board = HearingDay.load_days_for_range(@start_date, @end_date)
    else
      video_and_co, travel_board = HearingDay.load_days_for_regional_office(regional_office, @start_date, @end_date)
    end

    @hearings = json_hearings(video_and_co)
    @tbhearings = json_tb_hearings(travel_board)
    respond_to do |format|
      format.html do
        render "hearings/schedule_index"
      end
      format.json do
        render json: {
          hearings: @hearings,
          tbhearings: @tbhearings
        }
      end
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

  def update
    return record_not_found unless hearing

    updated_hearing = HearingDay.update_hearing_day(hearing, params)
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
    params.require("hearing").permit(:board_member,
                                     :representative)
  end

  def create_params
    params.require("hearing").permit(:hearing_type,
                                     :hearing_date,
                                     :room,
                                     :board_member,
                                     :representative)
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

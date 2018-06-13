class Hearings::HearingDayController < ApplicationController
  before_action :verify_access
  before_action :check_hearing_schedule_out_of_service

  # Controller to add and update hearing schedule days.

  # show schedule days for date range provided
  def index
    @start_date = params[:start_date].nil? ? (Date.today - 365.days) : Date.parse(params[:start_date])
    @end_date = params[:end_date].nil? ? Date.today : Date.parse(params[:end_date])
    video_and_co, travel_board = HearingDay.load_days_for_range(@start_date, @end_date)
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

  def set_application
    RequestStore.store[:application] = "hearings"
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

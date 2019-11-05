# frozen_string_literal: true

class Hearings::HearingDayController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_view_hearing_schedule_access
  before_action :verify_access_to_hearings, only: [:update]
  before_action :verify_build_hearing_schedule_access, only: [:destroy, :create]
  skip_before_action :deny_vso_access, only: [:index, :show]

  # show schedule days for date range provided
  def index
    respond_to do |format|
      format.html do
        render "hearings/index"
      end

      format.json do
        if hearing_day_range.valid?
          render json: {
            hearings: json_hearing_days(hearing_days_in_range_for_user.map(&:to_hash)),
            startDate: hearing_day_range.start_date,
            endDate: hearing_day_range.end_date
          }
        else
          hearing_day_range_invalid
        end
      end
    end
  end

  def show
    render json: {
      hearing_day: json_hearing_day(hearing_day.to_hash).merge(
        hearings: hearing_day.hearings_for_user(current_user).map { |hearing| hearing.quick_to_hash(current_user.id) }
      )
    }
  end

  def index_with_hearings
    range = HearingDayRange.new(
      Time.zone.today.beginning_of_day,
      Time.zone.today.beginning_of_day + 182.days,
      regional_office
    )

    if range.valid?
      range.open_hearing_days_with_hearings_hash(current_user.id)

      render json: { hearing_days: json_hearing_days(hearing_days_with_hearings) }
    else
      hearing_day_range_invalid(range)
    end
  end

  # Create a hearing schedule day
  def create
    return no_available_rooms unless hearing_day_rooms.rooms_are_available?

    hearing = HearingDay.create_hearing_day(create_params)
    return invalid_record_error(hearing) if hearing.nil?

    render json: {
      hearing: json_hearing_day(hearing)
    }, status: :created
  end

  def update
    hearing_day.update!(update_params)
    render json: hearing_day.to_hash
  end

  def destroy
    hearing_day.confirm_no_children_records
    hearing_day.destroy!
    render json: {}
  end

  private

  def hearing_day
    @hearing_day ||= HearingDay.find(hearing_day_id)
  end

  def hearing_day_id
    params[:id]
  end

  def hearing_day_range
    @hearing_day_range ||= HearingDayRange.new(
      params[:start_date], params[:end_date], params[:regional_office]
    )
  end

  def hearing_days_in_range_for_user
    if return_all_upcoming_hearing_days?
      hearing_day_range.load_days
    else
      hearing_day_range.load_days_for_user(current_user)
    end
  end

  def return_all_upcoming_hearing_days?
    ActiveRecord::Type::Boolean.new.deserialize(params[:show_all]) && current_user&.roles&.include?("Hearing Prep")
  end

  def hearing_day_rooms
    @hearing_day_rooms ||= HearingDayRoomService.new(params)
  end

  def update_params
    params.permit(:judge_id,
                  :regional_office,
                  :hearing_key,
                  :request_type,
                  :room,
                  :bva_poc,
                  :notes,
                  :lock)
      .merge(updated_by: current_user)
  end

  def create_params
    params.permit(:request_type,
                  :scheduled_for,
                  :room,
                  :judge_id,
                  :regional_office,
                  :notes,
                  :bva_poc)
      .merge(created_by: current_user, updated_by: current_user)
  end

  def invalid_record_error(hearing_day)
    render json: {
      "errors": ["title": COPY::INVALID_RECORD_ERROR_TITLE, "detail": hearing_day.errors.full_messages.join(" ,")]
    }, status: :bad_request
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record Not Found",
        "detail": "Record with that ID is not found"
      ]
    }, status: :not_found
  end

  def hearing_day_range_invalid(range = hearing_day_range)
    render json: {
      "errors": range.errors.messages.map do |_key, message|
        {
          title: "Hearing Day Range Request is Invalid",
          details: message
        }
      end
    }, status: :bad_request
  end

  def json_hearing_days(hearing_days)
    hearing_days.each_with_object([]) do |hearing, result|
      result << json_hearing_day(hearing)
    end
  end

  def json_hearing_day(hearing_day)
    hearing_day.as_json.each_with_object({}) do |(key, value), converted|
      converted[key] = if key == "room"
                         HearingDayMapper.label_for_room(value)
                       elsif key == "regional_office" && !value.nil?
                         converted["regional_office_key"] = value
                         HearingDayMapper.city_for_regional_office(value)
                       else
                         value
                       end
    end
  end

  def no_available_rooms_error
    if params[:request_type] == HearingDay::REQUEST_TYPES[:central]
      {
        "title": COPY::ADD_HEARING_DAY_MODAL_CO_HEARING_ERROR_MESSAGE_TITLE %
          Date.parse(params[:scheduled_for]).strftime("%m/%d/%Y"),
        "detail": COPY::ADD_HEARING_DAY_MODAL_CO_HEARING_ERROR_MESSAGE_DETAIL,
        "status": 400
      }
    else
      {
        "title": COPY::ADD_HEARING_DAY_MODAL_VIDEO_HEARING_ERROR_MESSAGE_TITLE %
          Date.parse(params[:scheduled_for]).strftime("%m/%d/%Y"),
        "detail": COPY::ADD_HEARING_DAY_MODAL_VIDEO_HEARING_ERROR_MESSAGE_DETAIL,
        "status": 400
      }
    end
  end

  def no_available_rooms
    render json: {
      "errors": [no_available_rooms_error]
    }, status: :not_found
  end
end

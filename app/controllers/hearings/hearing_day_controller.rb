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
        start_date = validate_start_date(params[:start_date])
        end_date = validate_end_date(params[:end_date])
        regional_office = HearingDayMapper.validate_regional_office(params[:regional_office])
        hearing_days = HearingDay.list_upcoming_hearing_days(start_date, end_date, current_user, regional_office)

        render json: {
          hearings: json_hearing_days(hearing_days.map(&:to_hash)),
          startDate: start_date,
          endDate: end_date
        }
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
    regional_office = HearingDayMapper.validate_regional_office(params[:regional_office])

    hearing_days_with_hearings = HearingDay.open_hearing_days_with_hearings_hash(
      Time.zone.today.beginning_of_day,
      Time.zone.today.beginning_of_day + 182.days,
      regional_office,
      current_user.id
    )

    render json: { hearing_days: json_hearing_days(hearing_days_with_hearings) }
  end

  # Create a hearing schedule day
  def create
    return no_available_rooms unless rooms_are_available

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

  def update_params
    params.permit(:judge_id,
                  :regional_office,
                  :hearing_key,
                  :request_type,
                  :room,
                  :bva_poc,
                  :notes,
                  :lock)
      .merge(updated_by: current_user.css_id)
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

  def validate_start_date(start_date)
    start_date.nil? ? (Time.zone.today.beginning_of_day - 30.days) : Date.parse(start_date)
  end

  def validate_end_date(end_date)
    end_date.nil? ? (Time.zone.today.beginning_of_day + 365.days) : Date.parse(end_date)
  end

  def invalid_record_error(hearing)
    render json: {
      "errors": ["title": COPY::INVALID_RECORD_ERROR_TITLE, "detail": hearing.errors.full_messages.join(" ,")]
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

  def json_hearing_days(hearings)
    hearings.each_with_object([]) do |hearing, result|
      result << json_hearing_day(hearing)
    end
  end

  def json_hearing_day(hearing)
    hearing.as_json.each_with_object({}) do |(key, value), converted|
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

  def rooms_are_available
    # Coming from Add Hearing Day modal but no room required
    if do_not_assign_room
      params.delete(:assign_room)
      params[:room] = ""
      return true
    end
    # Return if coming from regular create from RO algorithm
    # where no assign_room variable is included in params
    return true unless params.key?(:assign_room)

    # Coming from Add Hearing Day modal and room required
    available_room = if params[:request_type] == HearingDay::REQUEST_TYPES[:central]
                       select_co_available_room
                     else
                       select_video_available_room
                     end

    params.delete(:assign_room)
    params[:room] = available_room if !available_room.nil?
    !available_room.nil?
  end

  def do_not_assign_room
    params.key?(:assign_room) && (!params[:assign_room] || params[:assign_room] == "false")
  end

  def select_co_available_room
    hearing_count_by_room = HearingDay.where(scheduled_for: params[:scheduled_for], request_type: params[:request_type])
      .group(:room).count
    room_count = hearing_count_by_room["2"]
    "2" unless !(room_count.nil? || room_count == 0)
  end

  def select_video_available_room
    hearing_count_by_room = HearingDay.where(scheduled_for: params[:scheduled_for], request_type: params[:request_type])
      .group(:room).count
    available_room = nil
    (1..HearingRooms::ROOMS.size).each do |hearing_room|
      room_count = hearing_count_by_room[hearing_room.to_s]
      if hearing_room != 2 && (room_count.nil? || room_count == 0)
        available_room = hearing_room.to_s
        break
      end
    end
    available_room
  end

  def no_available_rooms
    render json: {
      "errors": [
        "title": "No rooms available",
        "detail": "All rooms are taken for the date selected."
      ]
    }, status: :not_found
  end
end

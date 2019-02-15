class Hearings::HearingDayController < HearingScheduleController
  before_action :verify_build_hearing_schedule_access, only: [:destroy, :create]

  # show schedule days for date range provided
  def index
    start_date = validate_start_date(params[:start_date])
    end_date = validate_end_date(params[:end_date])
    regional_office = HearingDayMapper.validate_regional_office(params[:regional_office])

    hearings = HearingDay.load_days(start_date, end_date, regional_office)

    respond_to do |format|
      format.html do
        render "hearing_schedule/index"
      end
      format.json do
        render json: {
          hearings: json_hearings(HearingDay.array_to_hash(hearings[:vacols_hearings] + hearings[:caseflow_hearings])),
          startDate: start_date,
          endDate: end_date
        }
      end
    end
  end

  def show
    hearing_day = HearingDay.find_hearing_day(nil, params[:id])
    hearing_day_hash = HearingDay.to_hash(hearing_day)

    hearings, regional_office = fetch_hearings(hearing_day_hash, params[:id]).values_at(:hearings, :regional_office)

    hearing_day_options = HearingDay.hearing_days_with_hearings_hash(
      Time.zone.today.beginning_of_day,
      Time.zone.today.beginning_of_day + 365.days,
      regional_office
    )

    if hearing_day.is_a?(HearingDay)
      hearings += hearing_day.hearings
    end

    render json: {
      hearing_day: json_hearing(hearing_day_hash).merge(
        hearings: hearings.map { |hearing| hearing.to_hash(current_user.id) },
        hearing_day_options: hearing_day_options
      )
    }
  end

  def index_with_hearings
    regional_office = HearingDayMapper.validate_regional_office(params[:regional_office])

    hearing_days_with_hearings = HearingDay.hearing_days_with_hearings_hash(
      Time.zone.today.beginning_of_day,
      Time.zone.today.beginning_of_day + 182.days,
      regional_office,
      current_user.id
    )

    render json: { hearing_days: json_hearings(hearing_days_with_hearings) }
  end

  # Create a hearing schedule day
  def create
    return no_available_rooms unless rooms_are_available

    hearing = HearingDay.create_hearing_day(create_params)
    return invalid_record_error(hearing) if hearing.nil?

    render json: {
      hearing: json_hearing(hearing)
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

  def fetch_hearings(hearing_day, id)
    unless hearing_day[:request_type] == "V" || hearing_day[:request_type] == "C"
      return {
        hearings: [],
        regional_office: nil
      }
    end

    {
      hearings: HearingRepository.fetch_hearings_for_parent(id),
      regional_office: (hearing_day[:request_type] == "C") ? "C" : hearing_day[:regional_office]
    }
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
      "errors": ["title": "Record is invalid", "detail": hearing.errors.full_messages.join(" ,")]
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

  def json_created_hearings(hearings)
    json_hash = ActiveModelSerializers::SerializableResource.new(
      hearings,
      each_serializer: ::Hearings::HearingDaySerializer
    ).as_json

    format_for_client(json_hash)
  end

  def json_hearings(hearings)
    hearings.each_with_object([]) do |hearing, result|
      result << json_hearing(hearing)
    end
  end

  def json_hearing(hearing)
    hearing.as_json.each_with_object({}) do |(k, v), converted|
      converted[k] = if k == "room"
                       HearingDayMapper.label_for_room(v)
                     elsif k == "regional_office" && !v.nil?
                       converted["regional_office_key"] = v
                       HearingDayMapper.city_for_regional_office(v)
                     elsif k == "request_type"
                       HearingDayMapper.label_for_type(v)
                     else
                       v
                     end
    end
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

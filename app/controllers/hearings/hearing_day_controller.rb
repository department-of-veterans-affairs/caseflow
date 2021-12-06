# frozen_string_literal: true

class Hearings::HearingDayController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess
  include Pagy::Backend

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
          pagy, hearing_days = pagy(hearing_day_range.hearing_days)

          serialized_hearing_days = ::HearingDaySerializer.serialize_collection(
            hearing_days
          )

          render json: {
            hearings: serialized_hearing_days,
            startDate: hearing_day_range.start_date,
            endDate: hearing_day_range.end_date,
            pagination: pagy_metadata(pagy)
          }
        else
          hearing_day_range_invalid
        end
      end
    end
  end

  def show
    render json: {
      hearing_day: hearing_day.to_hash.merge(
        hearings: hearing_day.hearings_for_user(current_user).map { |hearing| hearing.quick_to_hash(current_user.id) }
      )
    }
  end

  def index_with_hearings
    if hearing_day_range.valid?
      serialized_hearing_days = ::HearingDaySerializer.serialize_collection(
        hearing_day_range.all_hearing_days
      )

      render json: { hearing_days: serialized_hearing_days }
    else
      hearing_day_range_invalid
    end
  end

  def create
    return no_available_rooms unless hearing_day_rooms.rooms_are_available?

    hearing_day = HearingDay.create(create_params.merge(room: hearing_day_rooms.available_room))

    render json: { hearing: hearing_day.to_hash }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: {
      "errors": [
        "title": error.class.to_s,
        "detail": error.message
      ]
    }, status: :bad_request
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
    @hearing_day ||= HearingDay.find(params[:id])
  end

  def hearing_day_range
    @hearing_day_range ||= HearingDayRange.new(
      hearing_day_range_params
    )
  end

  ## action is either index or index_with_hearings
  def default_range_start_date
    default = Time.zone.today.beginning_of_day
    # if vso users visit hearings/schedule page, show hearing days starting from today by default
    default -= 30.days if params[:action] == "index" && !current_user&.vso_employee?
    default
  end

  def range_start_date
    params[:start_date].nil? ? default_range_start_date : Date.parse(params[:start_date])
  rescue ArgumentError
    nil
  end

  def default_range_end_date
    default = Time.zone.today.beginning_of_day
    # if vso users visit hearings/schedule page, only show hearings 2 months out by default
    default + if params[:action] == "index"
                current_user&.vso_employee? ? 60.days : 365.days
              else
                182.days
              end
  end

  def range_end_date
    params[:end_date].nil? ? default_range_end_date : Date.parse(params[:end_date])
  rescue ArgumentError
    nil
  end

  def hearing_day_rooms
    @hearing_day_rooms ||= HearingDayRoomAssignment.new(
      request_type: params[:request_type],
      assign_room: params[:assign_room],
      scheduled_for: params[:scheduled_for],
      room: params[:room]
    )
  end

  def hearing_day_range_params
    params.permit(
      :regional_office,
      :show_all
    ).merge(
      start_date: range_start_date,
      end_date: range_end_date,
      user: current_user
    )
  end

  def update_params
    params.permit(:judge_id,
                  :regional_office,
                  :hearing_key,
                  :request_type,
                  :room,
                  :bva_poc,
                  :notes,
                  :first_slot_time,
                  :slot_length_minutes,
                  :number_of_slots,
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
                  :number_of_slots,
                  :first_slot_time,
                  :slot_length_minutes,
                  :bva_poc)
      .merge(created_by: current_user, updated_by: current_user)
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record Not Found",
        "detail": "Record with that ID is not found"
      ]
    }, status: :not_found
  end

  def hearing_day_range_invalid
    render json: {
      "errors": hearing_day_range.errors.messages.map do |_key, message|
        {
          title: "Hearing Day Range Request is Invalid",
          details: message
        }
      end
    }, status: :bad_request
  end

  def no_available_rooms
    key = (params[:request_type] == HearingDay::REQUEST_TYPES[:central]) ? "CO" : "VIDEO"

    render json: {
      "errors": [
        "title": COPY.const_get("ADD_HEARING_DAY_MODAL_#{key}_HEARING_ERROR_MESSAGE_TITLE") %
                 Date.parse(params[:scheduled_for]).strftime("%m/%d/%Y"),
        "detail": COPY.const_get("ADD_HEARING_DAY_MODAL_#{key}_HEARING_ERROR_MESSAGE_DETAIL"),
        "status": 400
      ]
    }, status: :not_found
  end
end

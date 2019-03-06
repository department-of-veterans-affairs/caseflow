# frozen_string_literal: true

class Hearings::SchedulePeriodsController < HearingScheduleController
  before_action :verify_build_hearing_schedule_access

  def index
    respond_to do |format|
      format.html { render "hearing_schedule/index" }
      format.json { render json: { schedule_periods: SchedulePeriod.all.map(&:to_hash) } }
    end
  end

  def show
    sp = if schedule_period.can_be_finalized? && !schedule_period.submitting_to_vacols
           schedule_period.to_hash.merge(
             can_finalize: schedule_period.can_be_finalized?,
             hearing_days: schedule_period.algorithm_assignments.map do |hearing_day|
               hearing_day[:regional_office] = RegionalOffice.city_state_by_key(hearing_day[:regional_office])
               hearing_day
             end
           )
         else
           schedule_period.to_hash.merge(
             can_finalize: schedule_period.can_be_finalized?
           )
         end
    render json: { schedule_period: sp }
  rescue HearingSchedule::Errors::NotEnoughAvailableDays,
         HearingSchedule::Errors::CannotAssignJudges => error
    render_error_for_show_action(error)
  end

  def create
    file_name = params["schedule_period"]["type"] + Time.zone.now.to_s + ".xlsx"
    uploaded_file = Base64Service.to_file(params["file"], file_name)
    S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + file_name, uploaded_file.tempfile, :filepath)
    schedule_period = SchedulePeriod.create!(schedule_period_params.merge(user_id: current_user.id,
                                                                          file_name: file_name))
    render json: { id: schedule_period.id }
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.message }
  end

  def update
    if schedule_period.can_be_finalized?
      schedule_period.schedule_confirmed(schedule_period.algorithm_assignments)
      render json: { id: schedule_period.id }
    else
      render json: { error: "This schedule period cannot be finalized." }, status: :unprocessable_entity
    end
  end

  def download
    schedule_period = SchedulePeriod.find(params[:schedule_period_id])
    schedule_period.spreadsheet
    send_file(
      schedule_period.spreadsheet_location,
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: "attachment; filename='#{schedule_period.file_name}'"
    )
  end

  private

  def schedule_period_params
    params.require(:schedule_period).permit(:type, :file, :start_date, :end_date)
  end

  def schedule_period
    SchedulePeriod.find(params[:schedule_period_id])
  end

  def render_error_for_show_action(error)
    render(
      json: {
        error: error.message, details: error.details, type: schedule_period.type
      },
      status: :unprocessable_entity
    )
  end
end

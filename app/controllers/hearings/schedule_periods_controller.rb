# frozen_string_literal: true

class Hearings::SchedulePeriodsController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess

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
             hearing_days: schedule_period.algorithm_assignments.map(&:to_hash)
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

  # Route to create a hearing schedule
  def create
    file_name = params["schedule_period"]["type"] + Time.zone.now.to_s + ".xlsx"
    uploaded_file = Base64Service.to_file(params["schedule_period"]["file"], file_name)
    S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + file_name, uploaded_file.tempfile, :filepath)
    create_params = schedule_period_params.merge(user_id: current_user.id, file_name: file_name)

    assign_hearing_days_or_create_schedule_period(create_params)
  rescue StandardError => error
    render(
      json: {
        errors: [
          title: error.class.to_s,
          details: error.message
        ]
      },
      status: :bad_request
    )
  end

  # Route to finalize and confirm a hearing schedule
  def update
    if params[:schedule_period_id] == "confirm_judge_assignments"
      hearing_days = params["schedule_period"]
      confirm_assignments(hearing_days)
      render json: { success: true }
    elsif schedule_period.can_be_finalized?
      schedule_period.schedule_confirmed(schedule_period.algorithm_assignments)
      render json: { id: schedule_period.id }
    else
      render(
        json: {
          errors: [
            title: "Finalize Schedule Period",
            details: "This schedule period cannot be finalized."
          ]
        },
        status: :unprocessable_entity
      )
    end
  end

  # Route to download uploaded spreadsheets
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

  def assign_hearing_days_or_create_schedule_period(create_params)
    if params["schedule_period"]["type"] == "JudgeSchedulePeriod"
      hearing_days = assign_vljs_to_hearing_days(create_params)
      render json: { hearing_days: hearing_days }
    else
      schedule_period = SchedulePeriod.create!(create_params)
      render json: { id: schedule_period.id }
    end
  end

  def assign_vljs_to_hearing_days(assignments)
    file_name = assignments["file_name"]
    spreadsheet_location = File.join(Rails.root, "tmp", "hearing_schedule", "spreadsheets", file_name)
    s3_file_location = SchedulePeriod::S3_SUB_BUCKET + "/" + file_name

    S3Service.fetch_file(s3_file_location, spreadsheet_location)
    spreadsheet = Roo::Spreadsheet.open(spreadsheet_location, extension: :xlsx)
    spreadsheet_data = HearingSchedule::GetSpreadsheetData.new(spreadsheet)

    validate_spreadsheet = HearingSchedule::ValidateJudgeSpreadsheet.new(spreadsheet_data)
    errors = validate_spreadsheet.validate
    if errors.count > 0
      errors.each { |error| fail error }
    end

    hearing_days = HearingDay.where(id: spreadsheet_data.judge_assignments.pluck(:hearing_day_id))

    hearing_days.map do |hearing_day|
      data = spreadsheet_data.judge_assignments.find { |day| day[:hearing_day_id] == hearing_day.id }
      result = hearing_day.to_hash
      result[:judge_css_id] = data[:judge_css_id].to_i
      result[:judge_name] = data[:name]
      result
    end
  end

  def confirm_assignments(hearing_days)
    ActiveRecord::Base.transaction do
      begin
        hearing_days.each do |day|
          hearing_day = HearingDay.find(day["hearing_day_id"])
          hearing_day.update(judge: User.find_by_css_id(day["judge_css_id"]))
        end
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end
  end

  def schedule_period_params
    params.require(:schedule_period).permit(:type, :start_date, :end_date)
  end

  def schedule_period
    SchedulePeriod.find(params[:schedule_period_id])
  end

  def render_error_for_show_action(error)
    render(
      json: {
        errors: [
          title: error.message,
          details: error.details,
          type: schedule_period.type
        ]
      },
      status: :unprocessable_entity
    )
  end
end

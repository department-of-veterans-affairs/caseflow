class Hearings::SchedulePeriodsController < HearingScheduleController
  def index
    respond_to do |format|
      format.html { render "hearing_schedule/index" }
      format.json { render json: { schedule_periods: SchedulePeriod.all.map(&:to_hash) } }
    end
  end

  # rubocop:disable Metrics/MethodLength
  def show
    # TODO: remove sleep, rubocop disable, and faked data when we actually run the algorithm!
    sleep(2)
    render json: { schedule_period: SchedulePeriod.find(params[:schedule_period_id]).to_hash.merge(
      hearing_days: [
        {
          hearing_date: "2018-06-04",
          hearing_type: "Video",
          regional_office: "St. Petersburg, FL",
          room: "1",
          judge: "Sarah Smith"
        },
        {
          hearing_date: "2018-06-04",
          hearing_type: "Video",
          regional_office: "Baltimore, MD",
          room: "1",
          judge: "Sarah Smith"
        },
        {
          hearing_date: "2018-06-04",
          hearing_type: "Video",
          regional_office: "Portland, OR",
          room: "1",
          judge: "Sarah Smith"
        }
      ]
    ) }
  end
  # rubocop:enable Metrics/MethodLength

  def create
    file_name = params["schedule_period"]["type"] + Time.zone.now.to_s + ".xlsx"
    uploaded_file = Base64Service.to_file(params["file"], file_name)
    S3Service.store_file(file_name, uploaded_file.tempfile, :filepath)
    schedule_period = SchedulePeriod.create!(schedule_period_params.merge(user_id: current_user.id,
                                                                          file_name: file_name))
    render json: { id: schedule_period.id }
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.message }
  end

  def update
    schedule_period = SchedulePeriod.find(params[:schedule_period_id])
    if schedule_period.can_be_finalized?
      schedule_period.schedule_confirmed(schedule_period.ro_hearing_day_allocations)
    end
    render json: { id: schedule_period.id }
  end

  def download
    schedule_period = SchedulePeriod.find(params[:schedule_period_id])
    file_name = schedule_period.file_name.to_s
    file_location = schedule_period.spreadsheet_location.to_s
    schedule_period.spreadsheet
    send_file(
      file_location,
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: "attachment; filename='DownloadCopy_#{file_name}'"
    )
  end

  def schedule_period_params
    params.require(:schedule_period).permit(:type, :file, :start_date, :end_date)
  end
end

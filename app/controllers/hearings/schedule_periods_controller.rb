class Hearings::SchedulePeriodsController < HearingScheduleController
  def index
    respond_to do |format|
      format.html { render "hearing_schedule/index" }
      format.json { render json: { schedule_periods: SchedulePeriod.all.map(&:to_hash) } }
    end
  end
  def show
    schedule_period = SchedulePeriod.find(params[:schedule_period_id])
    render json: { schedule_period: schedule_period.to_hash.merge(
      hearing_days: schedule_period.ro_hearing_day_allocations.map do |hearing_day|
        regional_office = RegionalOffice::CITIES[hearing_day[:regional_office]]
        hearing_day[:regional_office] = "#{regional_office[:city]}, #{regional_office[:state]}"
        hearing_day
      end
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

  def schedule_period_params
    params.require(:schedule_period).permit(:type, :file, :start_date, :end_date)
  end
end

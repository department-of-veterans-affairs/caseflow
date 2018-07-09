class Hearings::SchedulePeriodsController < HearingScheduleController
  def index
    respond_to do |format|
      format.html { render "hearing_schedule/index" }
      format.json { render json: { schedule_periods: SchedulePeriod.all.map(&:to_hash) } }
    end
  end

  def create
    schedule_period = RoSchedulePeriod.create!(schedule_period_params.merge(user_id: current_user.id))
    render json: { id: schedule_period.id }
  end

  def schedule_period_params
    params.require(:schedule_period).permit(:type, :start_date, :end_date, :file_name)
  end
end

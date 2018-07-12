class Hearings::SchedulePeriodsController < HearingScheduleController
  def index
    respond_to do |format|
      format.html { render "hearing_schedule/index" }
      format.json { render json: { schedule_periods: SchedulePeriod.all.map(&:to_hash) } }
    end
  end

  def show
    render json: { schedule_period: SchedulePeriod.find(params[:schedule_period_id]).to_hash }
  end

  def create
    schedule_period = SchedulePeriod.create!(schedule_period_params.merge(user_id: current_user.id))
    render json: { id: schedule_period.id }
  end

  def schedule_period_params
    params.require(:schedule_period).permit(:type, :file_name, :start_date, :end_date)
  end
end

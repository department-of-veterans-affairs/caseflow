class Hearings::SchedulePeriodsController < HearingScheduleController
  def index
    respond_to do |format|
      format.html { render "hearing_schedule/index" }
      format.json { render json: { schedule_periods: Hearings::SchedulePeriod.all.map(&:to_hash) } }
    end
  end
end

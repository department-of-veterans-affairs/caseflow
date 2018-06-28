class Hearings::SchedulePeriodsController < ApplicationController
  def index
    respond_to do |format|
      format.json { render json: { schedule_periods: Hearings::SchedulePeriod.all.map(&:to_hash) } }
    end
  end
end

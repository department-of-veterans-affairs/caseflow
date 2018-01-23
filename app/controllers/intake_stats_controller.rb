require "json"

class IntakeStatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def show
    CalculateIntakeStatsJob.perform_later

    @stats = {
      daily: 0...30,
      weekly: 0...26,
      monthly: 0...24
    }[interval].map { |i| IntakeStats.offset(time: IntakeStats.now, interval: interval, offset: i) }
  end

  def logo_name
    "Intake"
  end

  def interval
    @interval ||= IntakeStats::INTERVALS.find { |i| i.to_s == params[:interval] } || :monthly
  end
  helper_method :interval

  private

  def verify_access
    verify_system_admin
  end
end

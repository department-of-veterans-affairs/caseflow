# frozen_string_literal: true

require "json"

class IntakeStatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def show
    CalculateIntakeStatsJob.perform_later

    @stats = {
      daily: 0...30,
      weekly: 0...26,
      monthly: 0...24,
      fiscal_yearly: 0...3
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

  def interval_names
    {
      daily: "Daily",
      weekly: "Weekly",
      monthly: "Monthly",
      fiscal_yearly: "By Fiscal Year"
    }
  end
  helper_method(:interval_names)

  def verify_access
    verify_authorized_roles("Admin Intake")
  end
end

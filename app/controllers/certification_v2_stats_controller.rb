require "json"

class CertificationV2StatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def show
    @stats = {
      hourly: 0...24,
      daily: 0...30,
      weekly: 0...26,
      monthly: 0...24
    }[interval].map { |i| CertificationV2Stats.offset(time: CertificationV2Stats.now, interval: interval, offset: i) }
  end

  def logo_name
    "CertificationV2"
  end

  private

  def verify_access
    verify_system_admin
  end

  def interval
    @interval ||= CertificationV2Stats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
  helper_method :interval
end
